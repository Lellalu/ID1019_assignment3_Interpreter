defmodule Env do
  def new() do
    []
  end
  # Adds a new variable binding to the environment
  def add(id, str, env) do
    add(id, str, env, [])
  end
  def add(id, str, [], acc) do
    [{id, str} | acc]
  end
  def add(id, str, [{v, _} | rest], acc) when v === id do
    acc ++ [{id, str} | rest]
  end
  def add(id, str, [bind | rest], acc) do
    add( id, str, rest, acc ++ [bind])
  end

  # Looks up a variable in the environment
  def lookup(_, []) do
    nil
  end
  def lookup(id, [{id, str} | _]) do
    {id, str}
  end
  def lookup(id, [_|rest]) do
    lookup(id, rest)
  end

  # Removes specified variables from the environment
  def remove(_, []) do [] end
  def remove(ids, [{id, str} | rest]) do
    if id in ids do
      remove(ids, rest)
    else
      [{id, str} | remove(ids, rest)]
    end
  end

  def closure([], _) do
    []
  end
  def closure([head | tail], env) do
    case lookup(head, env) do
      :nil -> :error
      {_, str} -> [{head, str} | closure(tail, env)]
    end
  end

  def args([], [], closure) do
    closure
  end
  def args([par_head | par_tail], [strs_head | strs_tail], closure) do
    [{par_head, strs_head} | args(par_tail, strs_tail, closure)]
  end

  def test() do
    env = Env.new()
    env = Env.add(:a, 1, env)
    env = Env.add(:b, 2, env)
    env = Env.add(:a, 3, env)
    Env.remove([:a, :b], env)
  end
end
