set -x

# Remove resources directory
rm -rvf resources/

# Create resources directory
mkdir resources

# Copy files into resources
cp -Rvf server.rb intro.txt components conf events help lib objects traits util resources/

# Build gem
gem build kams.gemspec

#Clean up
rm -rf resources
