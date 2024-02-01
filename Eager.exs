defmodule Eager do
  def eval(exp) do
    case eval_seq(exp, Env.new()) do
      :error ->
        :error
      {:ok, str} ->
        {:ok, str}
    end
  end

  def eval_expr({:atm, id}, _) do {:ok, id} end
  def eval_expr({:var, id}, env) do
    case Env.lookup(id, env) do
      nil -> :error
      {_, str} -> {:ok, str}
    end
  end
  def eval_expr({:cons, head, tail}, env) do
    case eval_expr(head, env) do
      :error -> :error
      {:ok, hs} ->
        case eval_expr(tail, env) do
          :error -> :error
          {:ok, ts} -> {:ok, {hs, ts}}
        end
    end
  end
  def eval_expr({:case, expr, cls}, env) do
    case eval_expr(expr, env) do
      :error ->
        :error
      {_, str} ->
        eval_cls(cls, str, env)
    end
  end
  def eval_expr({:lambda, par, free, seq}, env) do
    case Env.closure(free, env) do
      :error -> :error
      closure -> {:ok, {:closure, par, seq, closure}}
    end
  end
  def eval_expr({:apply, expr, args}, env) do
    case eval_expr(expr, env) do
      :error -> :error
      {_, {:closure, par, seq, closure}} ->
        case eval_args(args, env) do
          :error -> :error
          {_, strs} ->
            env = Env.args(par, strs, closure)
            eval_seq(seq, env)
        end
    end
  end
  def eval_expr({:fun, id}, env) do
    {par, seq} = apply(Prgm, id, [])
    {:ok, {:closure, par, seq, Env.new()}}
  end

  def eval_args(args, env) do
    case eval_args(args, [], env) do
      :error -> :error
      strs ->
        if :error in strs do
          :error
        else
          {:ok, strs}
        end
    end
  end
  def eval_args([], _, _) do
    []
  end
  def eval_args([head | tail], rest, env) do
    case eval_expr(head, env) do
      :error -> :error
      {_, str} -> [str | eval_args(tail, rest, env)]
    end
  end

  def eval_cls([], _, _) do
    :error
  end
  def eval_cls([{:clause, ptr, seq} | rest_cls], str, env) do
    case eval_match(ptr, str, env) do
      :fail ->
        eval_cls(rest_cls, str, env)
      {_, env} ->
        eval_seq(seq, env)
    end
  end

  def eval_match(:ignore, _, env) do {:ok, env} end
  def eval_match({:atm, id}, id, env) do
    {:ok, env}
  end
  def eval_match({:var, id}, str, env) do
    case Env.lookup(id, env) do
      :nil -> {:ok, Env.add(id, str, env)}
      {_, ^str} -> {:ok, env}
      {_, _} -> :fail
    end
  end
  def eval_match({:cons, hp, tp}, {head, tail}, env) do
    case eval_match(hp, head, env) do
      :fail ->
        :fail
      {:ok, env} ->
        eval_match(tp, tail, env)
    end
  end
  def eval_match(_, _, _) do :fail end

  def extract_vars({:var, v}) do
    [v]
  end
  def extract_vars({:cons, {:var, v}, tail}) do
    [v | extract_vars(tail)]
  end
  def extract_vars(_) do
    []
  end

  def eval_scope(pattern, env) do
    Env.remove(extract_vars(pattern), env)
  end

  def eval_seq([exp], env) do
    eval_expr(exp, env)
  end

  def eval_seq([{:match, pattern, expr} | rest], env) do
    case eval_expr(expr, env) do
      :error ->
        :error
      {_, str} ->
        restricted_env = eval_scope(pattern, env)
        case eval_match(pattern, str, restricted_env) do
          :fail ->
            :error
          {_, updated_env} ->
            eval_seq(rest, updated_env)
        end
    end
  end

  def test1() do
    eval_expr({:atm, :a}, [])
  end

  def test2() do
    eval_expr({:var, :x}, [{:x, :a}])
  end

  def test3() do
    eval_expr({:var, :x}, [])
  end

  def test4() do
    eval_expr({:cons, {:atm, :x}, {:cons, {:atm, :y}, {:atm, :z}}},  [])
  end

  def test5() do
    eval_match({:atm, :a}, :a, [])
  end

  def test6() do
    eval_match({:var, :x}, :a, [])
  end

  def test7() do
    eval_match({:var, :x}, :a, [{:x, :a}])
  end

  def test8() do
    eval_match({:var, :x}, :a, [{:x, :b}])
  end

  def test9() do
    eval_match({:cons, {:var, :x}, {:var, :x}}, {:a, :b}, [])
  end

  def test10() do
    extract_vars({:cons, {:var, :x}, {:atm, :x}})
  end

  def test11() do
    eval_scope([{:var, :x}, :ignore], [{:x, 1}, {:y, 2}])
  end

  def test12() do
    seq = [
      {:match, {:var, :x}, {:atm, :a}},
      {:match, {:var, :y}, {:cons, {:var, :x}, {:atm, :b}}},
      {:match, {:cons, :ignore, {:var, :z}}, {:var, :y}}, {:var, :z}
    ]
    eval(seq)
  end

  def test13() do
    seq = [
      {:match, {:var, :x}, {:atm, :a}},
      {:case, {:var,:x},
        [{:clause, {:atm, :b}, [{:atm,:ops}]},
         {:clause, {:atm,:a}, [{:atm,:yes}]}]}
    ]
    eval_seq(seq, Env.new())
  end

  def test14() do
    seq = [
      {:match, {:var, :x}, {:atm, :a}},
      {:match, {:var, :f},
        {:lambda, [:y], [:x], [{:cons, {:var, :x}, {:var, :y}}]}},
      {:apply, {:var, :f}, [{:atm, :b}]}
    ]
    eval_seq(seq, Env.new())
  end

  def test15() do
    seq = [{:match, {:var, :x},
            {:cons, {:atm, :a}, {:cons, {:atm, :b}, {:atm, []}}}},
          {:match, {:var, :y},
            {:cons, {:atm, :c}, {:cons, {:atm, :d}, {:atm, []}}}},
          {:apply, {:fun, :append}, [{:var, :x}, {:var, :y}]}
          ]
    eval_seq(seq, Env.new())
  end
end
