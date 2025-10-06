# frozen_string_literal: true

require 'set'

# CustomDiffStrategies provides various strategies for calculating differences
# between Saffron term extraction results in the Delta of Delta algorithm.
module CustomDiffStrategies
  
  # Strategy focusing on term frequency and weight changes
  class TermWeightStrategy
    def self.calculate_delta(result_a, result_b)
      terms_a = result_a[:terms] || {}
      terms_b = result_b[:terms] || {}
      
      # Extract term sets
      terms_a_set = Set.new(terms_a.keys)
      terms_b_set = Set.new(terms_b.keys)
      
      added_terms = terms_b_set - terms_a_set
      removed_terms = terms_a_set - terms_b_set
      common_terms = terms_a_set & terms_b_set
      
      # Calculate weight changes for common terms
      weight_changes = {}
      total_weight_change = 0.0
      
      common_terms.each do |term|
        weight_a = extract_weight(terms_a[term])
        weight_b = extract_weight(terms_b[term])
        
        if weight_a != weight_b
          change = weight_b - weight_a
          weight_changes[term] = {
            old_weight: weight_a,
            new_weight: weight_b,
            change: change,
            relative_change: weight_a > 0 ? change / weight_a : Float::INFINITY
          }
          total_weight_change += change.abs
        end
      end
      
      # Calculate magnitude based on:
      # 1. Proportion of terms added/removed
      # 2. Magnitude of weight changes
      # 3. Relative importance of changed terms
      
      total_terms = [terms_a_set.size, terms_b_set.size].max
      return 0.0 if total_terms == 0
      
      structural_change = (added_terms.size + removed_terms.size).to_f / total_terms
      weight_change_magnitude = common_terms.empty? ? 0.0 : total_weight_change / common_terms.size
      
      magnitude = (structural_change * 0.6) + (weight_change_magnitude * 0.4)
      
      {
        strategy: 'term_weight',
        magnitude: magnitude,
        details: {
          added_terms: added_terms.to_a,
          removed_terms: removed_terms.to_a,
          common_terms: common_terms.to_a,
          weight_changes: weight_changes,
          structural_change: structural_change,
          weight_change_magnitude: weight_change_magnitude
        }
      }
    end
    
    private
    
    def self.extract_weight(term_data)
      return 0.0 if term_data.nil?
      return term_data if term_data.is_a?(Numeric)
      return term_data['weight'] if term_data.is_a?(Hash) && term_data['weight']
      return term_data['score'] if term_data.is_a?(Hash) && term_data['score']
      return term_data['value'] if term_data.is_a?(Hash) && term_data['value']
      0.0
    end
  end
  
  # Strategy focusing on semantic similarity between term sets
  class SemanticSimilarityStrategy
    def self.calculate_delta(result_a, result_b)
      terms_a = result_a[:terms] || {}
      terms_b = result_b[:terms] || {}
      
      # Use term similarity data if available
      term_sim_a = result_a[:term_similarity] || {}
      term_sim_b = result_b[:term_similarity] || {}
      
      # Calculate Jaccard similarity for quick baseline
      terms_a_set = Set.new(terms_a.keys)
      terms_b_set = Set.new(terms_b.keys)
      
      intersection = terms_a_set & terms_b_set
      union = terms_a_set | terms_b_set
      
      jaccard_similarity = union.empty? ? 0.0 : intersection.size.to_f / union.size
      jaccard_distance = 1.0 - jaccard_similarity
      
      # If we have term similarity matrices, use them for more sophisticated analysis
      semantic_distance = 0.0
      if !term_sim_a.empty? && !term_sim_b.empty?
        semantic_distance = calculate_semantic_matrix_distance(term_sim_a, term_sim_b)
      end
      
      # Combine Jaccard distance with semantic distance
      magnitude = semantic_distance > 0 ? (jaccard_distance * 0.3 + semantic_distance * 0.7) : jaccard_distance
      
      {
        strategy: 'semantic_similarity',
        magnitude: magnitude,
        details: {
          jaccard_similarity: jaccard_similarity,
          jaccard_distance: jaccard_distance,
          semantic_distance: semantic_distance,
          intersection_size: intersection.size,
          union_size: union.size
        }
      }
    end
    
    private
    
    def self.calculate_semantic_matrix_distance(sim_a, sim_b)
      # Calculate distance between similarity matrices
      # This is a placeholder - implement based on actual Saffron similarity format
      common_terms = Set.new(sim_a.keys) & Set.new(sim_b.keys)
      return 0.0 if common_terms.empty?
      
      total_distance = 0.0
      comparisons = 0
      
      common_terms.each do |term1|
        common_terms.each do |term2|
          next if term1 == term2
          
          sim_a_val = extract_similarity(sim_a, term1, term2)
          sim_b_val = extract_similarity(sim_b, term1, term2)
          
          if sim_a_val && sim_b_val
            total_distance += (sim_a_val - sim_b_val).abs
            comparisons += 1
          end
        end
      end
      
      comparisons > 0 ? total_distance / comparisons : 0.0
    end
    
    def self.extract_similarity(sim_matrix, term1, term2)
      return nil unless sim_matrix[term1]
      
      if sim_matrix[term1].is_a?(Hash)
        sim_matrix[term1][term2]
      elsif sim_matrix[term1].is_a?(Array)
        # Handle array format if Saffron uses it
        nil
      else
        nil
      end
    end
  end
  
  # Strategy focusing on document-term distribution changes
  class DocumentDistributionStrategy
    def self.calculate_delta(result_a, result_b)
      doc_terms_a = result_a[:doc_terms] || {}
      doc_terms_b = result_b[:doc_terms] || {}
      
      # Calculate distribution entropy for each result
      entropy_a = calculate_term_distribution_entropy(doc_terms_a)
      entropy_b = calculate_term_distribution_entropy(doc_terms_b)
      
      entropy_change = (entropy_b - entropy_a).abs
      
      # Calculate document coverage changes
      docs_a = Set.new(doc_terms_a.keys)
      docs_b = Set.new(doc_terms_b.keys)
      
      added_docs = docs_b - docs_a
      removed_docs = docs_a - docs_b
      common_docs = docs_a & docs_b
      
      # Calculate term distribution changes within common documents
      distribution_changes = calculate_within_document_changes(doc_terms_a, doc_terms_b, common_docs)
      
      # Combine metrics
      total_docs = [docs_a.size, docs_b.size].max
      doc_structural_change = total_docs > 0 ? (added_docs.size + removed_docs.size).to_f / total_docs : 0.0
      
      magnitude = (entropy_change * 0.4) + (doc_structural_change * 0.3) + (distribution_changes * 0.3)
      
      {
        strategy: 'document_distribution',
        magnitude: magnitude,
        details: {
          entropy_a: entropy_a,
          entropy_b: entropy_b,
          entropy_change: entropy_change,
          added_docs: added_docs.to_a,
          removed_docs: removed_docs.to_a,
          common_docs: common_docs.to_a,
          doc_structural_change: doc_structural_change,
          distribution_changes: distribution_changes
        }
      }
    end
    
    private
    
    def self.calculate_term_distribution_entropy(doc_terms)
      return 0.0 if doc_terms.empty?
      
      # Calculate overall term frequency across all documents
      term_counts = Hash.new(0)
      total_terms = 0
      
      doc_terms.each do |doc, terms|
        if terms.is_a?(Hash)
          terms.each do |term, count|
            weight = extract_count(count)
            term_counts[term] += weight
            total_terms += weight
          end
        elsif terms.is_a?(Array)
          terms.each do |term|
            term_counts[term] += 1
            total_terms += 1
          end
        end
      end
      
      return 0.0 if total_terms == 0
      
      # Calculate entropy
      entropy = 0.0
      term_counts.each do |term, count|
        probability = count.to_f / total_terms
        entropy -= probability * Math.log2(probability) if probability > 0
      end
      
      entropy
    end
    
    def self.calculate_within_document_changes(doc_terms_a, doc_terms_b, common_docs)
      return 0.0 if common_docs.empty?
      
      total_change = 0.0
      common_docs.each do |doc|
        terms_a = normalize_doc_terms(doc_terms_a[doc])
        terms_b = normalize_doc_terms(doc_terms_b[doc])
        
        # Calculate cosine similarity between term vectors
        similarity = calculate_cosine_similarity(terms_a, terms_b)
        distance = 1.0 - similarity
        total_change += distance
      end
      
      total_change / common_docs.size
    end
    
    def self.normalize_doc_terms(terms)
      return {} if terms.nil?
      
      if terms.is_a?(Array)
        # Convert array to frequency hash
        freq = Hash.new(0)
        terms.each { |term| freq[term] += 1 }
        return freq
      elsif terms.is_a?(Hash)
        # Normalize weights
        return terms.transform_values { |v| extract_count(v) }
      end
      
      {}
    end
    
    def self.calculate_cosine_similarity(terms_a, terms_b)
      all_terms = (terms_a.keys + terms_b.keys).uniq
      return 0.0 if all_terms.empty?
      
      # Create vectors
      vector_a = all_terms.map { |term| terms_a[term] || 0.0 }
      vector_b = all_terms.map { |term| terms_b[term] || 0.0 }
      
      # Calculate dot product
      dot_product = vector_a.zip(vector_b).sum { |a, b| a * b }
      
      # Calculate magnitudes
      magnitude_a = Math.sqrt(vector_a.sum { |v| v * v })
      magnitude_b = Math.sqrt(vector_b.sum { |v| v * v })
      
      return 0.0 if magnitude_a == 0 || magnitude_b == 0
      
      dot_product / (magnitude_a * magnitude_b)
    end
    
    def self.extract_count(value)
      return value if value.is_a?(Numeric)
      return value['count'] if value.is_a?(Hash) && value['count']
      return value['weight'] if value.is_a?(Hash) && value['weight']
      return value['score'] if value.is_a?(Hash) && value['score']
      1.0
    end
  end
  
  # Composite strategy that combines multiple approaches
  class CompositeStrategy
    STRATEGIES = [
      TermWeightStrategy
      # SemanticSimilarityStrategy,
      # DocumentDistributionStrategy
    ].freeze
    
    def self.calculate_delta(result_a, result_b, weights: nil)
      # Default weights for each strategy
      weights ||= {
        'term_weight' => 0.4,
        'semantic_similarity' => 0.3,
        'document_distribution' => 0.3
      }
      
      strategy_results = {}
      total_magnitude = 0.0
      
      STRATEGIES.each do |strategy_class|
        result = strategy_class.calculate_delta(result_a, result_b)
        strategy_name = result[:strategy]
        strategy_results[strategy_name] = result
        
        weight = weights[strategy_name] || 0.0
        total_magnitude += result[:magnitude] * weight
      end
      
      {
        strategy: 'composite',
        magnitude: total_magnitude,
        details: {
          strategy_results: strategy_results,
          weights: weights
        }
      }
    end
  end
end