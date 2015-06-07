require 'haml'
require 'faml'
require 'hamlit'
require 'unindent'

module HamlitSpecHelper
  DEFAULT_OPTIONS = { ugly: true, escape_html: true }.freeze

  def parse_string(str)
    Hamlit::Parser.new.call(str)
  end

  def render_string(str, options = {})
    eval Hamlit::Engine.new(options).call(str)
  end

  def assert_render(haml, html, options = {})
    errs  = array_wrap(options.delete(:error_with) || [])
    impls = array_wrap(options.delete(:compatible_only) || [:haml, :faml] - errs)
    fails = [:haml, :faml] - impls - errs

    test = TestCase.new
    test.src_haml = haml.unindent
    test.hamlit_html = html.unindent

    expect(render_string(test.src_haml, options)).to eq(test.hamlit_html)
    impls.each { |i| expect_compatibility(i, test, options) }
    errs.each  { |i| expect_compatibility(i, test, options, type: :error) }
    fails.each { |i| expect_compatibility(i, test, options, type: :failure) }

    if TestCase.generate_docs? && (errs.any? || fails.any?)
      write_caller!(test)
      TestCase.incompatibilities << test
    end
  end

  def assert_parse(haml, &block)
    haml = haml.unindent
    ast  = block.call

    expect(parse_string(haml)).to eq(ast)
  end

  def assert_compile(before, after)
    result = described_class.new.call(before)
    expect(result).to eq(after)
  end

  private

  def write_caller!(test)
    line = caller.find{ |l| l =~ %r{spec/hamlit} }
    path, lineno = line.match(/^([^:]+):([0-9]+)/).to_a.last(2)
    test.lineno = lineno.to_i
    test.dir, test.file = path.gsub(%r{^.+spec/hamlit/}, '').split('/')
  end

  def expect_compatibility(impl, test, options, type: :success)
    case impl
    when :haml
      expect_implementation(impl, test, options, type) do |test, options|
        options = DEFAULT_OPTIONS.merge(options)
        Haml::Engine.new(test.src_haml, options).render(Object.new, {})
      end
    when :faml
      expect_implementation(impl, test, options, type) do |test, options|
        options = options.dup
        options.delete(:escape_html)
        eval Faml::Engine.new(options).call(test.src_haml)
      end
    end
  end

  def expect_implementation(impl, test, options, type, &block)
    if type == :error
      expect { block.call(test, options) }.to raise_error
      begin
        block.call(test, options)
      rescue Exception => e
        test.send(:"#{impl}_html=", e.to_s)
      end
      return
    end

    result = block.call(test, options)
    test.send(:"#{impl}_html=", result)

    case type
    when :success
      expect(test.hamlit_html).to eq(result)
    when :failure
      expect(test.hamlit_html).to_not eq(result)
    end
  end

  def array_wrap(arr)
    return arr if arr.is_a?(Array)
    [arr]
  end

  def tests
    @tests ||= []
  end
end

# This is used to generate a document automatically.
class TestCase < Struct.new(:file, :dir, :lineno, :src_haml, :haml_html, :faml_html, :hamlit_html)
  class << self
    def incompatibilities
      @incompatibilities ||= []
    end

    def generate_docs!
      prepare_dirs!

      incompatibilities.group_by(&:doc_path).each do |path, tests|
        doc = tests.sort_by(&:lineno).map(&:document).join("\n")
        full_path = File.join(doc_dir, path)
        File.write(full_path, doc)
      end
    end

    def generate_docs?
      ENV['AUTODOC']
    end

    private

    def prepare_dirs!
      system("rm -rf #{doc_dir}")
      incompatibilities.map(&:dir).uniq.each do |dir|
        system("mkdir -p #{doc_dir}/#{dir}")
      end
    end

    def doc_dir
      @doc_dir ||= File.expand_path('./doc')
    end
  end

  def document
    <<-DOC
# #{escape_markdown("#{file}:#{lineno}")}
## Input
```haml
#{src_haml}
```

## Output
### Hamlit
```html
#{hamlit_html}
```

### Haml
```html
#{haml_html}
```

### Faml
```html
#{faml_html}
```
    DOC
  end

  def doc_path
    File.join(dir, file.gsub(/_spec\.rb$/, '.md'))
  end

  private

  def escape_markdown(text)
    text.gsub(/_/, '\\_')
  end
end

RSpec.configure do |config|
  config.include HamlitSpecHelper

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.after(:suite) do
    TestCase.generate_docs! if TestCase.generate_docs?
  end
end
