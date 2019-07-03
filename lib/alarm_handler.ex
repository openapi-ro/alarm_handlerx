defmodule AlarmHandler do
  use GenEvent
  require Logger
  @moduledoc """
  Alarm handler republishing `:gen_event` events to a `Registry`

  Using this module `:os_mon alarms can be paired with calls to set/clear methods`
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
    {:ok, state}
  end
  def log_set_alarm( alarm_id, alarm_desc) do
    Logger.info("#{__MODULE__}(#{inspect self()}): alarm set: #{inspect(alarm_id)} value:#{inspect alarm_desc}")
  end
  def log_clear_alarm(  alarm_id) do
    Logger.info("#{__MODULE__}(#{inspect self()}): clear alarm: #{inspect(alarm_id)}")
  end
  def start_link() do
    require AlarmHandlex
    ret = GenEvent.start_link([name: __MODULE__])
    AlarmHandlex.on_set_alarm(:log_set_alarm)
    AlarmHandlex.on_clear_alarm(:log_clear_alarm)
    :gen_event.add_handler(:alarm_handler,__MODULE__,:alarm_handler.get_alarms())
    ret
  end
  @impl true
  def handle_event({:set_alarm, {alarm_id, alarm_desc}}, state) do
    Logger.info("#{__MODULE__}(#{inspect self()}) Set #{inspect(alarm_id)}")
    alarms =
      try do
        Registry.dispatch(@registry, :set_alarm ,fn list->
          Enum.each(list, fn
            {pid, {module, func_atom}} ->
              apply(module, func_atom,[alarm_id, alarm_desc])
            {pid,func} when is_function(func) -> func.(alarm_id, alarm_desc)
            end)
        end)
        Map.put(state.alarms, alarm_id, alarm_desc)
      rescue
        error ->
          Logger.error("failed setting alarm: #{inspect alarm_id}, #{inspect alarm_desc}, error:#{inspect error}")
          state.alarms
      end
    {:ok, %{state| alarms: alarms}}
  end
  @impl true
  def handle_event({:clear_alarm, alarm_id}, state) do
    Logger.info("#{__MODULE__}(#{inspect self()})Cleared #{inspect(alarm_id)}")
    alarms=
      try do
        Registry.dispatch(@registry, :clear_alarm ,fn list ->
          Enum.each(list, fn
            {pid, {module, func_atom}} ->
              apply(module, func_atom,[alarm_id])
            {pid, func} when is_function(func) -> func.(alarm_id)
            end)
        end)
        Map.delete(state.alarms, alarm_id)
      rescue
        error ->
          Logger.error("failed to clear alarm: #{inspect alarm_id}, error:#{inspect error}")
          state.alarms
      end
    {:ok, %{state| alarms: alarms}}
  end

  @impl true
  def handle_info({:notify_active_alarms,func}, state) do
    Enum.each(state[:alarms ] , fn
      {alarm_id,alarm_descr}->
        case func do
          {module, func_atom} ->
            apply(module, func_atom,[alarm_id, alarm_descr])
          func when is_function(func) -> func.(alarm_id, alarm_descr)
        end
      end)
    {:ok, state}
  end
end
