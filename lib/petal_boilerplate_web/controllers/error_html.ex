defmodule PetalBoilerplateWeb.ErrorHTML do
  use PetalBoilerplateWeb, :html

  def not_found_html do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="robots" content="noindex, nofollow" />
        <meta name="description" content="The requested page could not be found." />
        <title>Page Not Found · llmdb.xyz</title>
        <link rel="stylesheet" href="/assets/app.css" />
      </head>
      <body class="antialiased bg-white dark:bg-gray-900">
        <main class="min-h-screen flex items-center justify-center px-6">
          <div class="max-w-lg text-center">
            <p class="text-sm font-semibold uppercase tracking-wider text-blue-600">404</p>
            <h1 class="mt-3 text-4xl font-bold text-gray-950 dark:text-white">Page not found</h1>
            <p class="mt-4 text-gray-600 dark:text-gray-300">
              The requested model or page does not exist in the current catalog.
            </p>
            <a
              href="/"
              class="mt-8 inline-flex rounded-md bg-blue-600 px-4 py-2 font-semibold text-white"
            >
              Browse the model catalog
            </a>
          </div>
        </main>
      </body>
    </html>
    """
  end

  def render("404.html", _assigns) do
    Phoenix.HTML.raw(not_found_html())
  end

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
