#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(R6)

# R6 class
repclass <- R6Class("ReprexClass",
                    public = list(
                        data1 = NULL,
                        data2 = NULL,
                        data3 = NULL,
                        initialize = function() {
                            print("New object OK")
                        })
)



# Sub-module to import data
mod_import_data_ui <- function(id) {
    ns <- NS(id)
    selectInput(ns("dataset"), choices = c("mtcars", "sleep"), label = "Choose a dataset")
}
mod_import_data_server <- function(input, output, session, obj, dataid) {
    ns <- session$ns
    dt <- list(mtcars = mtcars, sleep = sleep) 
    observeEvent(input$dataset, {
        obj[[dataid]] <- dt[[input$dataset]]
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
mod_display_data_server <- function(input, output, session, obj, dataid){
    ns <- session$ns
    observeEvent(input$show, {
        # dat <- isolate(obj[[dataid]])
        # output$table <- renderDataTable(dat)
        output$table <- renderDataTable(obj[[dataid]]) 
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
mod_main_server <- function(input, output, session, obj, dataid){
    ns <- session$ns
    callModule(mod_import_data_server, "mod_import", obj = obj, dataid = dataid)
    callModule(mod_display_data_server, "mod_display", obj = obj, dataid = dataid)
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
    obj <- repclass$new()
    # First call of main module
    callModule(mod_main_server, "main_1", obj = obj, dataid = "data1")
    # Second call of main module
    callModule(mod_main_server, "main_2", obj = obj, dataid = "data2")
    # Third tab
    callModule(mod_import_data_server, "import_only", obj = obj, dataid = "data3")
    observeEvent(input[["import_only-dataset"]], {
        output$dat <- renderPrint(obj$data3)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
