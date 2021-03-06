%%%-------------------------------------------------------------------
%% @doc minidb db memory backend
%% @end
%%%-------------------------------------------------------------------

-module(minidb_db).

-author('Leonardo Rossi <leonardo.rossi@studenti.unipr.it>').

-export([
  all/1,
  delete/2,
  drop/1,
  export/2,
  find/2,
  fold/3,
  get/2,
  get/3,
  import/2,
  inc/3,
  init/0,
  is_empty/1,
  keys/1,
  patch/3,
  put/3,
  size/1,
  values/1
]).

%%====================================================================
%% API
%%====================================================================

init() -> #{}.

put(Key, Value, Data) -> Data#{Key => Value}.

patch(Key, Patch, Data) ->
  Value = maps:get(Key, Data, #{}),
  FinalValue = maps:merge(Value, Patch),
  Data#{Key => FinalValue}.

get(Key, Data) -> get(Key, Data, none).

get(Key, Data, Default) -> maps:get(Key, Data, Default).

find(Queries, Data) ->
  maps:fold(fun(_Key, Value, Acc) ->
        case check_constrains(Value, Queries) of
          true -> Acc ++ [Value];
          false -> Acc
        end
      end, [], Data).

inc(Key, Queries, Data) ->
  FinalValue = lists:foldl(fun({SubKey, Amount}, Value) ->
      NewValue = maps:get(SubKey, Value, 0) + Amount,
      Value#{SubKey => NewValue}
    end, maps:get(Key, Data, #{}), Queries),
  Data#{Key => FinalValue}.

delete(Key, Data) -> maps:remove(Key, Data).

fold(Fun, Init, Data) -> maps:fold(Fun, Init, Data).

import(BinaryKV, Data) ->
  {Key, Value} = erlang:binary_to_term(BinaryKV),
  Data#{Key => Value}.

export(Key, Value) -> erlang:term_to_binary({Key, Value}).

is_empty(Data) -> maps:size(Data) =:= 0.

drop(_) -> #{}.

all(Data) -> Data.

keys(Data) -> maps:keys(Data).

values(Data) -> maps:values(Data).

size(Data) -> maps:size(Data).

%% Private functions

check_constrains(Value, Queries) ->
  lists:all(fun({QueryKey, {Operator, QueryValue}}) ->
      Value2Check = maps:get(QueryKey, Value, none),
      minidb_query_operators:Operator(Value2Check, QueryValue)
    end, Queries).
