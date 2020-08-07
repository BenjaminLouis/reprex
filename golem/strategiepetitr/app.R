#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

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
