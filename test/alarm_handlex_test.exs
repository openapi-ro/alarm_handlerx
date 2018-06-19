defmodule AlarmHandlexTest do
  use ExUnit.Case
  doctest AlarmHandlex
  test "notification func test" do
    me = self()
    AlarmHandler.on_set_alarm(fn id, desc-> send(me, {:set_alarm, id, desc}) end )
  list = :alarm_handler.get_alarms()
   assert [] == Enum.reduce( list, list ,fn 
    _, list ->
      {id,desc}=
        receive do
          {:set_alarm, id, desc} -> {id,desc}
        end
      assert Enum.member?(list,{id, desc})
      List.delete(list,{id, desc})
    end)
  end
end
