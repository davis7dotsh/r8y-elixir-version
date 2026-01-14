defmodule R8yV4Web.CoreComponents do
  @moduledoc """
  Core UI components with a minimal, professional design.
  """
  use Phoenix.Component
  use Gettext, backend: R8yV4Web.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="fixed top-4 right-4 z-50 max-w-sm"
      {@rest}
    >
      <div class={[
        "rounded-lg border p-4 shadow-lg",
        @kind == :info && "bg-base-100 border-primary/30",
        @kind == :error && "bg-base-100 border-error/30"
      ]}>
        <div class="flex items-start gap-3">
          <.icon
            :if={@kind == :info}
            name="hero-information-circle"
            class={["size-5 shrink-0 text-primary"]}
          />
          <.icon
            :if={@kind == :error}
            name="hero-exclamation-circle"
            class={["size-5 shrink-0 text-error"]}
          />
          <div class="flex-1 text-sm">
            <p :if={@title} class="font-medium">{@title}</p>
            <p class="text-base-content/70">{msg}</p>
          </div>
          <button
            type="button"
            class="text-base-content/40 hover:text-base-content"
            aria-label={gettext("close")}
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button.
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any, default: nil
  attr :variant, :string, default: nil
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    base =
      "inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-medium rounded-md transition-colors disabled:opacity-50"

    variant_class =
      case assigns[:variant] do
        "primary" -> "bg-primary text-primary-content hover:bg-primary/90"
        _ -> "bg-base-300 text-base-content hover:bg-base-300/80"
      end

    assigns = assign(assigns, :computed_class, [base, variant_class, assigns[:class]])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@computed_class} {@rest}>{render_slot(@inner_block)}</.link>
      """
    else
      ~H"""
      <button class={@computed_class} {@rest}>{render_slot(@inner_block)}</button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField
  attr :errors, :list, default: []
  attr :checked, :boolean
  attr :prompt, :string, default: nil
  attr :options, :list
  attr :multiple, :boolean, default: false
  attr :class, :any, default: nil
  attr :error_class, :any, default: nil

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="mb-4">
      <label class="flex items-center gap-2 cursor-pointer">
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={@class || "checkbox checkbox-sm"}
          {@rest}
        />
        <span class="text-sm">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="mb-4">
      <label class="block">
        <span :if={@label} class="block text-sm text-base-content/60 mb-1.5">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class || "w-full select select-bordered bg-base-200",
            @errors != [] && "select-error"
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="mb-4">
      <label class="block">
        <span :if={@label} class="block text-sm text-base-content/60 mb-1.5">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea textarea-bordered bg-base-200 min-h-[100px]",
            @errors != [] && "textarea-error"
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="mb-4">
      <label class="block">
        <span :if={@label} class="block text-sm text-base-content/60 mb-1.5">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[@class || "w-full input input-bordered bg-base-200", @errors != [] && "input-error"]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp error(assigns) do
    ~H"""
    <p class="mt-1 flex items-center gap-1 text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-4" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-4", "mb-6"]}>
      <div>
        <h1 class="text-xl font-semibold">{render_slot(@inner_block)}</h1>
        <p :if={@subtitle != []} class="mt-1 text-sm text-base-content/60">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div :if={@actions != []} class="flex items-center gap-2">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table.
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil
  attr :row_click, :any, default: nil
  attr :row_href, :any, default: nil, doc: "Function that returns a navigate path for the row"
  attr :row_item, :any, default: &Function.identity/1

  slot :col, required: true do
    attr :label, :string
  end

  slot :action

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-base-300">
            <th :for={col <- @col} class="text-left py-3 px-3 font-medium text-base-content/60">
              {col[:label]}
            </th>
            <th :if={@action != []} class="py-3 px-3">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
          <%= for row <- @rows do %>
            <tr
              id={@row_id && @row_id.(row)}
              phx-click={@row_href && JS.navigate(@row_href.(@row_item.(row)))}
              class={[
                "border-b border-base-300/50 hover:bg-base-300/30",
                (@row_href || @row_click) && "cursor-pointer"
              ]}
            >
              <td
                :for={col <- @col}
                phx-click={@row_click && @row_click.(row)}
                class="py-3 px-3"
              >
                {render_slot(col, @row_item.(row))}
              </td>
              <td :if={@action != []} class="py-3 px-3">
                <div class="flex items-center justify-end gap-2">
                  {render_slot(@action, @row_item.(row))}
                </div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <dl class="divide-y divide-base-300">
      <div :for={item <- @item} class="py-3 flex gap-4">
        <dt class="text-sm text-base-content/60 w-32 shrink-0">{item.title}</dt>
        <dd class="text-sm">{render_slot(item)}</dd>
      </div>
    </dl>
    """
  end

  @doc """
  Renders an icon.
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 200,
      transition: {"ease-out duration-200", "opacity-0", "opacity-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 150,
      transition: {"ease-in duration-150", "opacity-100", "opacity-0"}
    )
  end

  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(R8yV4Web.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(R8yV4Web.Gettext, "errors", msg, opts)
    end
  end

  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
