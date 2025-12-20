# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.TypeSystem.ResourceFields do
  @moduledoc """
  Provides unified resource field type lookup.

  This module delegates to `AshIntrospection.TypeSystem.ResourceFields` for shared
  functionality.

  ## Variants

  - `get_field_type_info/2` - Looks up any field (public or private)
  - `get_public_field_type_info/2` - Looks up only public fields

  Both return `{type, constraints}` tuples, with `{nil, []}` for unknown fields.
  """

  alias AshIntrospection.TypeSystem.ResourceFields, as: SharedResourceFields

  @doc """
  Gets the type and constraints for any field on a resource.

  Checks attributes, calculations, relationships, and aggregates in order.
  Uses non-public Ash.Resource.Info functions to access all fields.

  ## Examples

      iex> get_field_type_info(MyApp.User, :name)
      {Ash.Type.String, []}

      iex> get_field_type_info(MyApp.User, :todos)
      {{:array, MyApp.Todo}, []}

      iex> get_field_type_info(MyApp.User, :unknown)
      {nil, []}
  """
  @spec get_field_type_info(module(), atom()) :: {atom() | tuple() | nil, keyword()}
  defdelegate get_field_type_info(resource, field_name), to: SharedResourceFields

  @doc """
  Gets the type and constraints for public fields only.

  Checks public attributes, calculations, aggregates, and relationships in order.
  Used for output formatting where we only want publicly accessible fields.

  ## Examples

      iex> get_public_field_type_info(MyApp.User, :name)
      {Ash.Type.String, []}

      iex> get_public_field_type_info(MyApp.User, :private_field)
      {nil, []}
  """
  @spec get_public_field_type_info(module(), atom()) :: {atom() | tuple() | nil, keyword()}
  defdelegate get_public_field_type_info(resource, field_name), to: SharedResourceFields

  @doc """
  Gets the resolved type for an aggregate field.

  Aggregates can have computed types based on the underlying field type.
  This function returns the fully resolved aggregate type.

  ## Examples

      iex> get_aggregate_type_info(MyApp.User, :todo_count)
      {Ash.Type.Integer, []}
  """
  @spec get_aggregate_type_info(module(), atom()) :: {atom() | nil, keyword()}
  defdelegate get_aggregate_type_info(resource, field_name), to: SharedResourceFields
end
