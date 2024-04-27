# опция для всех процессов сессии, как интерактивных, так и неинтерактивных
# options(repos = c(CRAN = "https://cran.rstudio.org"))
options(repos = c(CRAN = "https://mirror.truenetwork.ru/CRAN/"))

# options(download.file.method = "wget")
# options(langserver_library = "/home/ru/R/x86_64-pc-linux-gnu-library/4.2")
# options(langserver_library = "$HOME/.local/share/nvim/mason/packages/r-languageserver")

# только если работа идёт в интерактивном режиме
if (interactive()) {
  # меняем scientific-формат на обычный разрядный
  options(scipen = 999)
  # options(show.signif.stars = FALSE)
  # setHook(
  #   packageEvent("grDevices", "onLoad"),
  #   function(...) grDevices::ps.options(horizontal = FALSE)
  # )
  # set.seed(1234)
  .First <- function() cat("\n   Welcome to R!\n\n")
  .Last <- function() cat("\n   Goodbye!\n\n")
}
# Disable completion from the language server
# options(languageserver.server_capabilities =
#           list(completionProvider = FALSE, completionItemResolve = FALSE))

# languageserversetup::languageserver_install( confirmBeforeInstall = FALSE, strictLibrary = FALSE, fullReinstall = FALSE )
# languageserversetup::languageserver_add_to_rprofile()

# if (!require("BiocManager", quietly = TRUE))
#   install.packages("BiocManager")

# BiocManager::install(version = "3.18", ask = FALSE)
