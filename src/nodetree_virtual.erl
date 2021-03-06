%%% ====================================================================
%%% ``The contents of this file are subject to the Erlang Public License,
%%% Version 1.1, (the "License"); you may not use this file except in
%%% compliance with the License. You should have received a copy of the
%%% Erlang Public License along with this software. If not, it can be
%%% retrieved via the world wide web at http://www.erlang.org/.
%%%
%%%
%%% Software distributed under the License is distributed on an "AS IS"
%%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%%% the License for the specific language governing rights and limitations
%%% under the License.
%%%
%%%
%%% ejabberd, Copyright (C) 2002-2015   ProcessOne
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License along
%%% with this program; if not, write to the Free Software Foundation, Inc.,
%%% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%%%
%%%----------------------------------------------------------------------

%%% @doc The module <strong>{@module}</strong> is the PubSub node tree plugin that
%%% allow virtual nodes handling. This prevent storage of nodes.
%%% <p>PubSub node tree plugins are using the {@link gen_nodetree} behaviour.</p>
%%% <p>This plugin development is still a work in progress. Due to optimizations in
%%% mod_pubsub, this plugin can not work anymore without altering functioning.
%%% Please, send us comments, feedback and improvements.</p>

-module(nodetree_virtual).
-behaviour(gen_pubsub_nodetree).
-author('christophe.romain@process-one.net').

-include("pubsub.hrl").
-include("jlib.hrl").
-include("logger.hrl").

-export([init/3, terminate/2, options/0, set_node/1,
    get_node/3, get_node/2, get_node/1, get_nodes/2,
    get_nodes/1, get_parentnodes/3, get_parentnodes_tree/3,
    get_subnodes/3, get_subnodes_tree/3, create_node/6,
    delete_node/2]).

init(_Host, _ServerHost, _Opts) ->
    ok.

terminate(_Host, _ServerHost) ->
    ok.

options() ->
    [{virtual_tree, true}].

set_node(_Node) ->
    ok.

get_node(Host, Node, _From) ->
    get_node(Host, Node).

get_node(Host, Node) ->
    get_node(nodeidx(Host, Node)).

get_node(Nidx) ->
    {Host, Node} = nodeid(Nidx),
    Record = #pubsub_node{nodeid = Node, id = Nidx},
    ServerHost = mod_pubsub:serverhost(Host),
    Type = case mod_pubsub:config(ServerHost, plugins, undefined) of
        [T] -> T;
        _ -> Record#pubsub_node.type
    end,
    Module = jlib:binary_to_atom(<<"node_", (Type)/binary>>),
    Record#pubsub_node{owners = [{<<"">>, Host, <<"">>}],
	                   options = Module:options(),
                       type = Type}.

get_nodes(Host, _From) ->
    get_nodes(Host).

get_nodes(_Host) ->
    [].

get_parentnodes(_Host, _Node, _From) ->
    [].

get_parentnodes_tree(Host, Node, From) ->
    case get_node(Host, Node, From) of
	Node when is_record(Node, pubsub_node) -> [{0, [Node]}];
	_Error -> []
    end.

get_subnodes(Host, Node, _From) ->
    get_subnodes(Host, Node).

get_subnodes(_Host, _Node) ->
    [].

get_subnodes_tree(Host, Node, _From) ->
    get_subnodes_tree(Host, Node).

get_subnodes_tree(_Host, _Node) ->
    [].

create_node(Host, Node, _Type, _Owner, _Options, _Parents) ->
    {error, {virtual, {Host, Node}}}.

delete_node(Host, Node) ->
    [get_node(Host, Node)].

%% internal helper

nodeidx(Host, Node) -> term_to_binary({Host, Node}).
nodeid(Nidx) -> binary_to_term(Nidx).
