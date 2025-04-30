require "rails_helper"

describe Logging::TaggedLogger do
  let(:tagged_logger) { described_class.new }
  let(:rails_logger) { Rails.logger }

  before do
    tagged_logger.cleanup
  end

  describe "#tag" do
    subject(:tag) { tagged_logger.tag(tags) }

    let(:tags) { { foo: :bar } }
    let(:another_tag) { { another: :tag } }

    it "returns self" do
      expect(tag).to eq(tagged_logger)
    end

    it "returns a logger with the same methods" do
      expect(tag.methods).to eq(tagged_logger.methods)
    end

    describe "implements Logger instance methods" do
      shared_examples "logger method delegation" do |method|
        it "responds to ##{method}" do
          expect(tagged_logger).to respond_to(method)
        end

        it "delegates ##{method} to Rails.logger with tags" do
          allow(rails_logger).to receive(:tagged).and_call_original
          tagged_logger.tag(tags).send(method, "Test message")
          expect(rails_logger).to have_received(:tagged).with([tags])
        end
      end

      described_class::LEVELS.each do |method|
        include_examples "logger method delegation", method
      end
    end

    it "maintains a stack of tags when multiple tags are added" do
      tagged_logger.tag(tags)
      tagged_logger.tag(another_tag)
      tagged_logger.tag(tags)
      expect(tagged_logger.current_tags).to eq([tags, another_tag, tags])
    end

    it "passes the tags to the Rails logger" do
      allow(rails_logger).to receive(:tagged).and_call_original
      tagged_logger.tag(tags).info("Test message")
      expect(rails_logger).to have_received(:tagged).with([tags])
    end
  end

  describe "#cleanup" do
    let(:tags) { { foo: :bar } }

    it "clears the current tags" do
      tagged_logger.tag(tags)
      tagged_logger.cleanup
      expect(tagged_logger.current_tags).to be_empty
    end
  end

  it "maintains separate tags for different threads" do
    thread1_tags = { thread1: :tag }
    thread2_tags = { thread2: :tag }

    thread1 = Thread.new do
      tagged_logger.tag(thread1_tags)
      expect(tagged_logger.current_tags).to eq([thread1_tags])
    end

    thread2 = Thread.new do
      tagged_logger.tag(thread2_tags)
      expect(tagged_logger.current_tags).to eq([thread2_tags])
    end

    thread1.join
    thread2.join
  end

  it "handles nil tags gracefully" do
    expect { tagged_logger.tag(nil) }.not_to raise_error
    expect(tagged_logger.current_tags).to eq([nil])
  end

  it "handles empty tags gracefully" do
    tagged_logger.tag({})
    expect(tagged_logger.current_tags).to eq([{}])
  end
end
