%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2016-2021, 2600Hz
%%% @doc
%%% @author Pierre Fenoll
%%% @end
%%%-----------------------------------------------------------------------------
-module(knm_telnyx2_tests).

-include_lib("eunit/include/eunit.hrl").
-include("knm.hrl").

-define(DEBUG_WRITE(Format, Args), ?debugFmt(Format, Args)).
-define(DEBUG_APPEND(Format, Args), ?debugFmt(Format, Args)).

api_test_() ->
    Options = [
        {'account_id', ?RESELLER_ACCOUNT_ID},
        {'carriers', [<<"knm_telnyx2">>]},
        {'query_id', <<"QID">>}
    ],
    {setup,
        fun() ->
            {'ok', Pid} = knm_search:start_link(),
            Pid
        end,
        fun gen_server:stop/1, fun(_ReturnOfSetup) ->
            [
                find_numbers(Options),
                find_international_numbers(Options)
            ]
        end}.

find_numbers(Options0) ->
    [
        [
            {"Verify found numbers", ?_assertEqual(Limit, length(Results))},
            {"Verify results match queried prefix",
                ?_assertEqual('true', lists:all(matcher(<<"+1">>, Prefix), Results))}
        ]
        || {Prefix, Limit} <- [
        {<<"301359">>, 5},
        {<<"800">>, 2}
    ],
        Options <- [
            [
                {quantity, Limit},
                {prefix, Prefix}
                | Options0
            ]
        ],
        Results <- [knm_search:find(Options)]
    ].

find_international_numbers(Options0) ->
    Country = <<"GB">>,
    [
        [
            {"Verify found numbers", ?_assertEqual(Limit, length(Results))},
            {"Verify results match queried prefix",
                ?_assertEqual('true', lists:all(matcher(<<"+44">>, Prefix), Results))}
        ]
        || {Prefix, Limit} <- [{<<"1">>, 2}],
        Options <- [
            [
                {country, Country},
                {quantity, Limit},
                {prefix, Prefix}
                | Options0
            ]
        ],
        Results <- [knm_search:find(Options)]
    ].

matcher(Dialcode, Prefix) ->
    fun(Result) ->
        Num = <<Dialcode/binary, Prefix/binary>>,
        Size = byte_size(Num),
        case kz_json:get_value(<<"number">>, Result) of
            <<Num:Size/binary, _/binary>> -> 'true';
            _Else -> 'false'
        end
    end.

acquire_number_test_() ->
    Num = ?TEST_TELNYX_NUM,
    PN = knm_phone_number:from_number(Num),
    N = knm_number:set_phone_number(knm_number:new(), PN),
    Result = knm_telnyx2:acquire_number(N),
    [
        ?_assert(knm_phone_number:is_dirty(PN)),
        {"Verify number is still one inputed",
            ?_assertEqual(Num, knm_phone_number:number(knm_number:phone_number(Result)))}
    ].
