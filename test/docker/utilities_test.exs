defmodule Docker.UtilitiesTest do
  use ExUnit.Case, async: true

  alias Docker.Utilities

  require Utilities
  import Utilities

  doctest Utilities

  describe "to_unix/1" do
    test "should do nothing to an integer" do
      assert to_unix(1_669_611_627) == 1_669_611_627
    end

    test "should convert a `NaiveDateTime` to a UNIX timestamp" do
      assert to_unix(~N[2022-11-28 05:00:27.983075]) == 1_669_611_627
    end

    test "should convert a `DateTime` to a UNIX timestamp" do
      assert to_unix(~U[2022-11-28 05:00:27.983075Z]) == 1_669_611_627
    end

    test "should a `NaiveDateTime` string to a UNIX timestamp" do
      assert to_unix("2022-11-28T05:00:27.983075") == 1_669_611_627
    end

    test "should a `DateTime` string to a UNIX timestamp" do
      assert to_unix("2022-11-28T05:00:27.983075Z") == 1_669_611_627
    end

    test "should throw for any other data type" do
      assert_raise(ArgumentError, fn ->
        to_unix(false)
      end)
    end
  end

  describe "cast/2" do
    test "should transfer a key" do
      spec = %{a: %{to: :b}}

      assert cast(spec, a: :c) == %{b: :c}
    end

    test "should raise for a repeated non-repeatable key" do
      spec = %{a: %{to: :b}}

      assert_raise(ArgumentError, fn ->
        cast(spec, a: :c, a: :d)
      end)
    end

    test "should transfer the key into a list when repeatable" do
      spec = %{a: %{to: :b, repeatable: true}}

      assert cast(spec, a: :c, a: :d) == %{b: [:d, :c]}
    end

    test "should not to nothing if params has nothing" do
      assert cast(%{}, []) == %{}
    end

    test "should raise for unknown keys" do
      spec = %{}

      assert_raise(ArgumentError, fn ->
        cast(spec, a: :b)
      end)
    end

    test "should transform a key" do
      spec = %{a: %{to: :b, transform: &to_string/1}}

      assert cast(spec, a: :b) == %{b: "b"}
    end

    test "should transform a repeatable key" do
      spec = %{a: %{to: :b, repeatable: true, transform: &to_string/1}}

      assert cast(spec, a: :c, a: :d) == %{b: ["d", "c"]}
    end
  end
end
