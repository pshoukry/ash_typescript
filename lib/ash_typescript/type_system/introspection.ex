# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.TypeSystem.Introspection do
  @moduledoc """
  Core type introspection and classification for Ash types.

  This module delegates to `AshIntrospection.TypeSystem.Introspection` for shared
  functionality while providing TypeScript-specific features like backward compatibility
  for `typescript_field_names/0` callbacks.

  Used throughout the codebase for type checking, code generation, and runtime
  processing.
  """

  alias AshIntrospection.TypeSystem.Introspection, as: SharedIntrospection

  # ---------------------------------------------------------------------------
  # Delegated Functions (from AshIntrospection)
  # ---------------------------------------------------------------------------

  @doc """
  Checks if a module is an embedded Ash resource.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.is_embedded_resource?(MyApp.Accounts.Address)
      true

      iex> AshTypescript.TypeSystem.Introspection.is_embedded_resource?(MyApp.Accounts.User)
      false
  """
  defdelegate is_embedded_resource?(module), to: SharedIntrospection

  @doc """
  Checks if a type is a primitive Ash type (not a complex or composite type).

  Primitive types include basic types like String, Integer, Boolean, Date, UUID, etc.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.is_primitive_type?(Ash.Type.String)
      true

      iex> AshTypescript.TypeSystem.Introspection.is_primitive_type?(Ash.Type.Union)
      false
  """
  defdelegate is_primitive_type?(type), to: SharedIntrospection

  @doc """
  Classifies an Ash type into a category for processing purposes.

  Returns one of:
  - `:union_attribute` - Union type
  - `:embedded_resource` - Single embedded resource
  - `:embedded_resource_array` - Array of embedded resources
  - `:tuple` - Tuple type
  - `:attribute` - Simple attribute (default)

  ## Parameters
  - `type_module` - The Ash type module (e.g., Ash.Type.String, Ash.Type.Union)
  - `attribute` - The attribute struct containing type and constraints
  - `is_array` - Whether this is inside an array type

  ## Examples

      iex> attr = %{type: MyApp.Address, constraints: []}
      iex> AshTypescript.TypeSystem.Introspection.classify_ash_type(MyApp.Address, attr, false)
      :embedded_resource
  """
  defdelegate classify_ash_type(type_module, attribute, is_array), to: SharedIntrospection

  @doc """
  Extracts union types from an attribute's constraints.

  Handles both direct union types and array union types.

  ## Examples

      iex> attr = %{type: Ash.Type.Union, constraints: [types: [note: [...], url: [...]]]}
      iex> AshTypescript.TypeSystem.Introspection.get_union_types(attr)
      [note: [...], url: [...]]
  """
  defdelegate get_union_types(attribute), to: SharedIntrospection

  @doc """
  Extracts union types from type and constraints directly.

  Useful when you have constraints but not the full attribute struct.
  Handles both direct union types and array union types.

  ## Examples

      iex> constraints = [types: [note: [...], url: [...]]]
      iex> AshTypescript.TypeSystem.Introspection.get_union_types_from_constraints(Ash.Type.Union, constraints)
      [note: [...], url: [...]]
  """
  defdelegate get_union_types_from_constraints(type, constraints), to: SharedIntrospection

  @doc """
  Extracts the inner type from an array type.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.get_inner_type({:array, Ash.Type.String})
      Ash.Type.String

      iex> AshTypescript.TypeSystem.Introspection.get_inner_type(Ash.Type.String)
      Ash.Type.String
  """
  defdelegate get_inner_type(type), to: SharedIntrospection

  @doc """
  Checks if a type is an Ash type module.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.is_ash_type?(Ash.Type.String)
      true

      iex> AshTypescript.TypeSystem.Introspection.is_ash_type?(MyApp.CustomType)
      true

      iex> AshTypescript.TypeSystem.Introspection.is_ash_type?(:string)
      false
  """
  defdelegate is_ash_type?(module), to: SharedIntrospection

  @doc """
  Checks if constraints specify an instance_of that is an Ash resource.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.is_resource_instance_of?([instance_of: MyApp.Todo])
      true

      iex> AshTypescript.TypeSystem.Introspection.is_resource_instance_of?([])
      false
  """
  defdelegate is_resource_instance_of?(constraints), to: SharedIntrospection

  @doc """
  Checks if constraints include non-empty field definitions.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.has_field_constraints?([fields: [name: [type: :string]]])
      true

      iex> AshTypescript.TypeSystem.Introspection.has_field_constraints?([fields: []])
      false
  """
  defdelegate has_field_constraints?(constraints), to: SharedIntrospection

  @doc """
  Gets the type and constraints for a field from field specs.

  ## Examples

      iex> specs = [name: [type: :string], age: [type: :integer]]
      iex> AshTypescript.TypeSystem.Introspection.get_field_spec_type(specs, :name)
      {:string, []}

      iex> AshTypescript.TypeSystem.Introspection.get_field_spec_type(specs, :unknown)
      {nil, []}
  """
  defdelegate get_field_spec_type(field_specs, field_name), to: SharedIntrospection

  # ---------------------------------------------------------------------------
  # TypeScript-Specific Functions
  # ---------------------------------------------------------------------------

  @doc """
  Recursively unwraps Ash.Type.NewType to get the underlying type and constraints.

  When a type is wrapped in one or more NewType wrappers, this function
  recursively unwraps them until it reaches the base type. If the NewType
  has a `typescript_field_names/0` or `interop_field_names/0` callback and
  the constraints don't already have an `instance_of` key, it will add the
  NewType module as `instance_of` to preserve the reference for field name mapping.

  ## Parameters
  - `type` - The type to unwrap (e.g., MyApp.CustomType)
  - `constraints` - The constraints for the type

  ## Returns
  A tuple `{unwrapped_type, unwrapped_constraints}` where:
  - `unwrapped_type` is the final underlying type after all NewType unwrapping
  - `unwrapped_constraints` are the final constraints, potentially augmented with `instance_of`

  ## Examples

      iex> # Simple NewType with typescript_field_names
      iex> unwrap_new_type(MyApp.TaskStats, [])
      {Ash.Type.Struct, [fields: [...], instance_of: MyApp.TaskStats]}

      iex> # Nested NewTypes (outermost with callback wins)
      iex> unwrap_new_type(MyApp.Wrapper, [])
      {Ash.Type.String, [max_length: 100, instance_of: MyApp.Wrapper]}

      iex> # Non-NewType (returns unchanged)
      iex> unwrap_new_type(Ash.Type.String, [max_length: 50])
      {Ash.Type.String, [max_length: 50]}
  """
  def unwrap_new_type(type, constraints) do
    # Use the shared implementation with our TypeScript-aware callback
    SharedIntrospection.unwrap_new_type(type, constraints, &has_typescript_field_names?/1)
  end

  @doc """
  Checks if a type is a custom Ash type with a typescript_type_name callback.

  Custom types are Ash types that define a `typescript_type_name/0` callback
  to specify their TypeScript representation.

  Also checks for the generalized `interop_type_name/0` callback.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.is_custom_type?(MyApp.MyCustomType)
      true

      iex> AshTypescript.TypeSystem.Introspection.is_custom_type?(Ash.Type.String)
      false
  """
  def is_custom_type?(type) when is_atom(type) and not is_nil(type) do
    Code.ensure_loaded?(type) and
      (function_exported?(type, :typescript_type_name, 0) or
         function_exported?(type, :interop_type_name, 0)) and
      Spark.implements_behaviour?(type, Ash.Type)
  end

  def is_custom_type?(_), do: false

  # ---------------------------------------------------------------------------
  # TypeScript Field Names Helpers (with interop_field_names fallback)
  # ---------------------------------------------------------------------------

  @doc """
  Checks if a module has a typescript_field_names/0 or interop_field_names/0 callback.

  Checks for the generalized `interop_field_names/0` first, then falls back to
  the TypeScript-specific `typescript_field_names/0` for backward compatibility.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.has_typescript_field_names?(MyApp.TaskStats)
      true

      iex> AshTypescript.TypeSystem.Introspection.has_typescript_field_names?(Ash.Type.String)
      false
  """
  def has_typescript_field_names?(nil), do: false

  def has_typescript_field_names?(module) when is_atom(module) do
    Code.ensure_loaded?(module) &&
      (function_exported?(module, :interop_field_names, 0) ||
         function_exported?(module, :typescript_field_names, 0))
  end

  def has_typescript_field_names?(_), do: false

  @doc """
  Gets the typescript_field_names as a map, or empty map if not available.

  Checks for the generalized `interop_field_names/0` first, then falls back to
  the TypeScript-specific `typescript_field_names/0` for backward compatibility.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.get_typescript_field_names_map(MyApp.TaskStats)
      %{is_active?: "isActive", meta_1: "meta1"}
  """
  def get_typescript_field_names_map(nil), do: %{}

  def get_typescript_field_names_map(module) when is_atom(module) do
    cond do
      Code.ensure_loaded?(module) && function_exported?(module, :interop_field_names, 0) ->
        module.interop_field_names() |> Map.new()

      Code.ensure_loaded?(module) && function_exported?(module, :typescript_field_names, 0) ->
        module.typescript_field_names() |> Map.new()

      true ->
        %{}
    end
  end

  def get_typescript_field_names_map(_), do: %{}

  @doc """
  Builds a reverse mapping from client names to internal names.

  Can take either a map of field names or a module with typescript_field_names/0.

  ## Examples

      iex> AshTypescript.TypeSystem.Introspection.build_reverse_field_names_map(%{is_active?: "isActive"})
      %{"isActive" => :is_active?}

      iex> AshTypescript.TypeSystem.Introspection.build_reverse_field_names_map(MyApp.TaskStats)
      %{"isActive" => :is_active?, "meta1" => :meta_1}
  """
  def build_reverse_field_names_map(ts_field_names) when is_map(ts_field_names) do
    SharedIntrospection.build_reverse_field_names_map(ts_field_names)
  end

  def build_reverse_field_names_map(module) when is_atom(module) do
    module
    |> get_typescript_field_names_map()
    |> SharedIntrospection.build_reverse_field_names_map()
  end

  def build_reverse_field_names_map(_), do: %{}
end
