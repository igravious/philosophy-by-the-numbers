# Include core extensions once during Rails initialization
# This prevents ThreadError: "already initialized" during testing

# Load the extensions
require Rails.root.join('config/initializers/core_extensions/string/split_peas/core_extensions')
require Rails.root.join('config/initializers/core_extensions/array/joint_peas/core_extensions')

# Include them safely (only if not already included)
String.include CoreExtensions::String::SplitPeas unless String.include?(CoreExtensions::String::SplitPeas)
Array.include CoreExtensions::Array::JointPeas unless Array.include?(CoreExtensions::Array::JointPeas)
