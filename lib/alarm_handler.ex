defmodule AlarmHandler do
  use GenEvent
  require Logger
  @moduledoc """
  Alarm handler notifying when disk is full
  """

  @doc """
    intialization for both GenServer and gen_event
  """
  @registry AlarmHandlex.Registry
  @impl true
  def init(alarms) do
    state=
      alarms
      |> Enum.reduce(%{alarms:  %{}}, fn
        alarm, state->
          {:ok, state}=handle_event({:set_alarm, alarm}, state)
          state
      end)
    require IEx
    IEx.pry
    {:ok, state}
  end
  def log_set_alarm( alarm_id, alarm_desc) do
    Logger.info("#{__MODULE__}: alarm set: #{inspect(alarm_id)} value:#{inspect alarm_desc}")
  end
  def log_clear_alarm(  alarm_id) do
    Logger.info("#{__MODULE__}: clear alarm: #{inspect(alarm_id)}")
  end
  def start_link() do
    ret = GenEvent.start_link([name: __MODULE__])
    on_set_alarm(:log_set_alarm)
    on_clear_alarm(:log_clear_alarm)
    :gen_event.add_handler(:alarm_handler,__MODULE__,:alarm_handler.get_alarms())
    ret
  end
  @impl true
  def handle_event({:set_alarm, {alarm_id, alarm_desc}}, state) do
    Logger.info("Set #{inspect(alarm_id)}")
    alarms = Map.put(state.alarms, alarm_id, alarm_desc)
    Registry.dispatch(@registry, :set_alarm ,fn list->
      Enum.each(list, fn
        {pid, {module, func_atom}} ->
          apply(module, func_atom,[alarm_id, alarm_desc])
        end)
    end)
    {:ok, %{state| alarms: alarms}}
  end
  @impl true
  def handle_event({:clear_alarm, alarm_id}, state) do
    Logger.info("Cleared #{inspect(alarm_id)}")
    alarms=
      Map.delete(state.alarms, alarm_id)
    Registry.dispatch(@registry, :clear_alarm ,fn list ->
      Enum.each(list, fn
        {pid, {module, func_atom}} ->
          apply(module, func_atom,[alarm_id])
        end)
    end)
    {:ok, %{state| alarms: alarms}}
  end
  def on_set_alarm(func) when is_atom(func) do
    Registry.register(@registry, :set_alarm, {__MODULE__, func})
  end
  def on_clear_alarm(func) when is_atom(func) do
    Registry.register(@registry, :clear_alarm, {__MODULE__, func})
  end
end