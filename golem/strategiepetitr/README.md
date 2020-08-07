Compréhension stratégie du petit r
================

# Contexte

  - Création d’une application shiny avec le framework proposé par
    `{golem}`

  - Un module principal qui comprend 2 sous-modules qui ont besoin de
    communiquer ensemble

  - Le module principal est lui même répété 2 fois (tabPanel 1 et 2)

  - Les sous-modules peuvent être utilisés dans l’application en dehors
    du contexte du module principal (tabPanel 3)

  - Stratégie de communication utilisé : [stratégie du petit
    r](https://rtask.thinkr.fr/fr/la-communication-entre-modules-et-ses-caprices/)
    de la [ThinkR team](https://thinkr.fr/)

  - Problématique : sous-module 2 a besoin d’une sortie de sous-module 1
    (qui est donc dans la `reactiveValues()` appelée `r`) et je suis pas
    certain d’utiliser ce qu’il y a de mieux pour aller chercher ce dont
    a besoin le module 2

# Modules

## Premier sous-module

Le premier sous module permet de choisir un jeu de données (entre
`mtcars` et `sleep`). Le jeu de données est stocké dans
`r[[ns("import")]]`. J’encadre `"import"` par `ns()` car le module peut
être utilisé plusieurs fois donc les noms doivent être différents.

``` r
# Sub-module to import data
mod_import_data_ui <- function(id) {
    ns <- NS(id)
    selectInput(ns("dataset"), choices = c("mtcars", "sleep"), label = "Choose a dataset")
}
mod_import_data_server <- function(input, output, session, r){
    ns <- session$ns
    r[[ns("import")]] <- reactiveValues()
    dt <- list(mtcars = mtcars, sleep = sleep) 
    observeEvent(input$dataset, {
        r[[ns("import")]]$data <- dt[[input$dataset]]
    })
}
```

## Deuxième sous-module

Le deuxième module est celui qui montre les données lorsque’on clique
sur un `actionButton()`. Il permet également d’enregistrer les noms des
colonnes dans `r`. Pour montrer les données le module a besoin des
données qui sont stockés par le premier module dans
`r[[ns("import")]]`. Je n’ai pas trouvé un moyen d’aller chercher ces
données depuis l’intérieur du module, j’ai donc ajouté un argument à la
partie server appelé `pathtodata` qui permet d’aller les chercher. C’est
ici que je me demande si c’est la bonne approche ou si il y a plus
simple/élégant.

``` r
# Sub-module to display data
mod_display_data_ui <- function(id) {
    ns <- NS(id)
    tagList(
        actionButton(ns("show"), label = "Display data"),
        dataTableOutput(ns("table"))
    )
}
mod_display_data_server <- function(input, output, session, r, pathtodata){
    ns <- session$ns
    r[[ns("display")]] <- reactiveValues()
    observeEvent(input$show, {
        r[[ns("display")]]$colnames <- colnames(r[[pathtodata]]$data)
        dat <- isolate(r[[pathtodata]]$data)
        output$table <- renderDataTable(dat)
    })
}
```

## Module principal

Le module principal appelle juste les 2 sous-modules ici. On voit
l’argument `pathtodata` dont la valeur est passé à
`ns("mod_import-import")` : `ns()` pour reprendre le namespace du module
principal, `mod_import` c’est l’identifiant d’appelle du sous-module 1
et `import` c’est ce qui est ajouté par le module 1 pour créer la
`reactiveValues()`.

``` r
# Main module that contains both sub-modules
mod_main_ui <- function(id) {
    ns <- NS(id)
    tagList(
        mod_import_data_ui(ns("mod_import")),
        mod_display_data_ui(ns("mod_display"))
    )
}
mod_main_server <- function(input, output, session, r){
    ns <- session$ns
    callModule(mod_import_data_server, "mod_import", r = r)
    callModule(mod_display_data_server, "mod_display", r = r, pathtodata = ns("mod_import-import"))
}
```

# Application

Et voici l’application complète :

``` r
# UI part
ui <- fluidPage(
    
    # Application title
    titlePanel("Reprex app"),
    
    tabsetPanel(
        # First call of main module
        tabPanel(title = "Tab 1",
                 mod_main_ui("main_1")
        ),
        # Second call of main module
        tabPanel(title = "Tab 2",
                 mod_main_ui("main_2")
        ),
        # Third call of main module
        tabPanel(title = "Tab 3",
                 mod_import_data_ui("import_only"),
                 verbatimTextOutput("dat")
        )
    )
)

# Server part
server <- function(input, output, session) {
    r <- reactiveValues()
    # First call of main module
    callModule(mod_main_server, "main_1", r = r)
    # Second call of main module
    callModule(mod_main_server, "main_2", r = r)
    # Third tab
    callModule(mod_import_data_server, "import_only", r = r)
    output$dat <- renderPrint(r[["import_only-import"]]$data)
}

# Run the application 
shinyApp(ui = ui, server = server)
```
