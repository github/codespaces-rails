class StructuredLoggerTest < Minitest::Test
  def setup
    @logger = Logging::StructuredLogger.new
    Logging.mdc.clear
  end

  def test_tag_scoped
    @logger.tag(order_id: 123) do
      assert_equal 123, Logging.mdc[:order_id]
    end
    assert_empty Logging.mdc
  end

  def test_nested_overrides
    @logger.tag(a: 1) do
      assert_equal 1, Logging.mdc[:a]
      @logger.tag(a: 2) { assert_equal 2, Logging.mdc[:a] }
      assert_equal 1, Logging.mdc[:a]
    end
    refute Logging.mdc.key?(:a)
  end

  def test_push_and_pop
    @logger.push_tags(foo: "bar")
    assert_equal "bar", Logging.mdc[:foo]
    @logger.pop_tags(foo: nil)
    assert_empty Logging.mdc
  end

  def test_clear
    @logger.tag(x: "y")
    refute_empty Logging.mdc
    @logger.clear
    assert_empty Logging.mdc
  end

  def test_same_thread_shared_mdc
    another = Logging::StructuredLogger.new
    @logger.tag(session: "abc") do
      assert_equal "abc", Logging.mdc[:session]
      another.info("dummy")
    end
    assert_empty Logging.mdc
  end

  def test_thread_isolation
    @logger.tag(request_id: 99) do
      child_value = nil
      t = Thread.new { child_value = Logging.mdc[:request_id] }
      t.join
      assert_nil child_value
      assert_equal 99, Logging.mdc[:request_id]
    end
  end

  def test_thread_clear_independent
    cleared_in_child = nil
    t = Thread.new do
      @logger.tag(worker: "child")
      @logger.clear
      cleared_in_child = Logging.mdc.empty?
    end
    t.join
    assert cleared_in_child
    assert_empty Logging.mdc
  end
end
