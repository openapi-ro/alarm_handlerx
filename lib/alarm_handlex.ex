defmodule AlarmHandlex do
  @registry AlarmHandlex.Registry
  @moduledoc """
  Bridge between _erlang's_ [`:alarm_handler`](http://erlang.org/doc/man/alarm_handler.html) and
  Elixir's `Registry`.



  ### EXAMPLES
  ```
    iex> AlarmHandlex.on_set_alarm(fn alarm_id,alarm_desc ->
    ...> IO.puts "Alarm set: "<>inspect(alarm_id)<>", descr "<> inspect(alarm_desc)
    ...> end)|>
    ...> elem(0)
    :ok
  ```
  """

  @doc false
  def start(_type,_args) do
    import Supervisor.Spec
    children = [
      worker(Registry, [:duplicate, AlarmHandlex.Registry],id: AlarmHandlex.Registry ),
      worker(AlarmHandler, [] )
    ]
    opts = [strategy: :one_for_one, name: AlarmHandlex.Supervisor]
    Supervisor.start_link(children,opts)
  end


    @doc """
    Sets a callback for alarms.

    The callback function can be specified as
    - `func when is_function(func)`
    - `atom` where atom is the function name in the `__CALLER__` context

    Callback functions must accept two arguments: `alarm_id` and `alarm_descr`.
    See [`:alarm_handler`](http://erlang.org/doc/man/alarm_handler.html) for a description of these arguments

    Use `&on_set_alarm/2` to supply the callback in two arguments `module`, and `:function_name_atom`.
    The return value is the same as for the corresponding `&Registry.register/3`
  """
  @spec on_set_alarm(
    (alarm_id::any(), alarm_descr::any() -> any() ) |
    atom()
  ) :: {:ok, pid()} | {:error, {:already_registered, pid()}}

  defmacro on_set_alarm(func)    do
    require Logger
    Logger.error("on_set_alarm(f) macro called")
    case func do
      func when is_atom(func) ->
        quote do
          AlarmHandlex.on_set_alarm(unquote(__CALLER__.module), unquote(func))
        end
      func when is_function(func) ->
        quote location: :keep do
          ret=Registry.register(unquote(@registry), :set_alarm, unquote(func))
          send(:alarm_handler, {:notify_active_alarms, unquote(func)})
          ret
        end
      {:fn,_,_}=quoted_fn->
        quote location: :keep do
          ret=Registry.register(unquote(@registry), :set_alarm, unquote(func))
          send(:alarm_handler, {:notify_active_alarms, unquote(func)})
          ret
        end
    end
  end
  @doc """
    Same as `&on_set_alarm/1` , but accepting `module, func_atom` as arguments.

    Otherwhise behaves the same as `&on_set_alarm/1`
  """
  @spec on_set_alarm(
    module::atom(),
    function::atom()
  ) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  defmacro on_set_alarm(mod, func) when is_atom(mod) and is_atom(func) do
    quote location: :keep do
      Registry.register(@registry, :set_alarm, {unquote(mod), unquote(func)})
    end
  end
  
  @doc """
    Same as `&on_clear_alarm/1` , but accepting `module, func_atom` as arguments.

    Otherwhise behaves the same as `&on_clear_alarm/1`
  """
  @spec on_clear_alarm(
    module::atom() ,
    function::atom()
  ) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  defmacro on_clear_alarm(mod, func) when is_atom(mod) and is_atom(func) do
    quote do
      Registry.register(unquote(@registry), :clear_alarm, {unquote(mod), unquote(func)})
    end
  end
   @doc """
    Sets a callback for alarm removal(clearing).

    The callback function can be specified as
    - `func when is_function(func)`
    - `atom` where atom is the function name in the `__CALLER__` context

    Callback functions must accept one argument: `alarm_id`.
    See [`:alarm_handler`](http://erlang.org/doc/man/alarm_handler.html) for a description of these arguments

    Use `&on_clear_alarm/2` to supply the callback in two arguments `module`, and `:function_name_atom`.
    The return value is the same as for the corresponding `&Registry.register/3`
  """
  @spec on_clear_alarm(
    (alarm_id::any() -> any() ) |
    atom()
  ) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  defmacro on_clear_alarm(func) when is_function(func) do
    quote do
      Registry.register(unquote(@registry), :clear_alarm, unquote(func))
    end
  end
  defmacro on_clear_alarm({:fn,_,_}=quoted_fun) do
    quote do
      Registry.register(unquote(@registry), :clear_alarm, unquote(quoted_fun))
    end
  end
  defmacro on_clear_alarm(func) when is_atom(func) do
    quote do
      AlarmHandlex.on_clear_alarm unquote(__CALLER__.module), unquote(func)
    end
  end
end
