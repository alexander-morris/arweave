-module(ar_merkle).
-export([root/2, root/3]).
-export([add_hash/2, add_wallet/2]).
-export([block_hash_list_to_merkle_root/1, wallet_list_to_merkle_root/1]).

-include("ar.hrl").
-include_lib("eunit/include/eunit.hrl").

%%% Module for building and manipulating generic and specific merkle trees.

%% @doc Take a prior merkle root and add a new peice of data to it, optionally
%% providing a conversion function prior to hashing.
root(OldRoot, Data, Fun) -> root(OldRoot, Fun(Data)).
root(OldRoot, Data) ->
	crypto:hash(?MERKLE_HASH_ALG, << OldRoot/binary, Data/binary >>).

%% @doc Generate a new entire merkle tree from a BHL.
block_hash_list_to_merkle_root(BHL) ->
	lists:foldl(
		fun(BH, MR) -> root(MR, BH) end,
		<<>>,
		lists:reverse(BHL)
	).

%% @doc Generate a new wallet list merkle root from a WL.
wallet_list_to_merkle_root(WL) ->
	lists:foldl(
		fun(Wallet, MR) ->
			root(
				MR,
				Wallet,
				fun wallet_to_binary/1
			)
		end,
		<<>>,
		lists:reverse(WL)
	).

%% @doc Add a new hash to an existing merkle tree, resulting in a new Merkle root.
add_hash(MR, BH) -> root(MR, BH).

%% @doc Add a new formatted wallet entry to an existing wallet merkle tree and return the new root.
add_wallet(MR, Wallet) -> root(MR, Wallet, fun wallet_to_binary/1).

%%% Helper functions

%% @doc Turn a wallet into a binary, for addition to a Merkle tree.
wallet_to_binary({Addr, Balance, LastTX}) ->
	<< Addr/binary, (integer_to_binary(Balance))/binary, LastTX/binary >>.

%%% TESTS

basic_hash_root_generation_test() ->
	BH0 = crypto:strong_rand_bytes(32),
	BH1 = crypto:strong_rand_bytes(32),
	BH2 = crypto:strong_rand_bytes(32),
	MR0 = crypto:hash(?MERKLE_HASH_ALG, << <<>>/binary, BH0/binary>>),
	MR1 = crypto:hash(?MERKLE_HASH_ALG, << MR0/binary, BH1/binary>>),
	MR2 = crypto:hash(?MERKLE_HASH_ALG, << MR1/binary, BH2/binary>>),
	?assertEqual(MR2, block_hash_list_to_merkle_root([BH2, BH1, BH0])).