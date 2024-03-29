# default machine learning parametedef.proportion<-0.7
defCostRange<-2^seq(-15,3,2)
defGammaRange<-2^seq(-5,15,2)
defEpsilonRange<-c(seq(0,0.1,0.03), 0.2, seq(0.3,0.9,0.3))
maxK <-20
defNtree<-1000
defNumberOfIterations <- 80
defPercentageForTrainingSet <- 0.75
defDirectionInStepwiseRegression <-"backward"

#' RMSE
#' @description generates RMSE performance metric from predicted and
#' actual values
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param true
#' @param predicted
#' @return RMSE performance metric
#'
#' @examples
#' \dontrun{RMSE(true, predicted)}

RMSE <- function(true, predicted){
        RMSE <- sqrt(mean((predicted - true)^2))
        return(RMSE)
}

#' RSQUARE
#' @description generates RSQUARE performance metric from predicted and
#' actual values
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param true
#' @param predicted
#' @return RSquare performance metric
#'
#' @examples
#' \dontrun{RSQUARE(true, predicted)}

RSQUARE <- function(true, predicted){
        RSquare <- 1 - sum((predicted - true)^2) / sum((true - mean(true))^2)
        return(RSquare)
}

#' evalMetrics
#' @description generates RSQUARE and RMSE performance metric from predicted and
#' actual values
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param true
#' @param predicted
#' @return list containing RSquare and RMSE performance metric
#'
#' @examples
#' \dontrun{evalMetrics(true, predicted)}

evalMetrics <- function(true, predicted) {
        RSquare <- RSQUARE(true, predicted)
        RMSE = RMSE(true, predicted)
        return(list("RMSE" = RMSE, "RSquare" = RSquare))

}

#' gePretreatmentVector
#' @description converts string of pretreatment parameter to vector to be used
#' in data scaling before machine learning modeling
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param pretreatment pretreatment string object  provided by config file
#' @return vector
#'
#' @examples
#' \dontrun{gePretreatmentVector(pretreatment)}
#'
gePretreatmentVector <- function(pretreatment){
        # Pretreatment parameter is changed to vector as it is required by
        # caret::preProcess method.
        if (pretreatment == "no_pretreatment"){
                return(pretreatment)
        }
        if(pretreatment == "auto-scale"){
                return(c("center", "scale"))
        }
        if(pretreatment == "range-scale"){
                return(c("range"))
        }
        if(pretreatment == "mean-center"){
                return(c("center"))
        }
}

#' getRegressionParameters
#' @description creates  regressionParameterList which contains all relevant
#' information to be used by machine learning models. regressionParameterList
#' is used as an internal object passed through different functions in machine
#' learning modeling
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param mlm  machine learning model list
#' @param dataSet  dataFrame produced by analytical platforms
#' @return list of regression parameters
#'
#' @examples
#' \dontrun{getRegressionParameters(mlm, dataSet, platform )}

getRegressionParameters <- function(mlm, dataSet, platform){
        mlmParams <- strsplit(mlm, ":")[[1]]
        if(mlmParams[2] == "" || is.na(mlmParams[2]))
                mlmParams[2] <- "mean-center"
        if(mlmParams[3] == "" || is.na(mlmParams[3]))
                mlmParams[3] <- defNumberOfIterations
        if(mlmParams[4] == ""  || is.na(mlmParams[4]))
                mlmParams[4] <- defPercentageForTrainingSet
        if(mlmParams[5] == ""  || is.na(mlmParams[5]))
                mlmParams[5] <- defDirectionInStepwiseRegression

        # regressionParameterList object contains all necessary infırmation for a machine learning model to run
        regressionParameterList <- list("method" = mlmParams[1], "pretreatment" =  mlmParams[2], "numberOfIterations" = as.numeric(mlmParams[3]),
                                        "percentageForTrainingSet" = as.numeric(mlmParams[4]), dataSet = dataSet, "platform" = platform, "direction" = mlmParams[5])

        return(regressionParameterList)
}

#' plotPrediction
#' @description draws plot of predicted values against actual values with RMSE value
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param model  machine learning model
#' @param testSet  dataFrame used for  machine learning model validation

#'
#' @examples
#' \dontrun{plotPrediction(model, testSet )}


plotPrediction <- function(model, testSet) {
        predicted <- predict(model, testSet)
        RMSE <- RMSE(testSet$TVC, predicted)
        plot(predicted, testSet$TVC, xlab='Predicted log10 TVC',
             ylab='Actual log10 TVC', main=paste('RMSE:', RMSE))
}

#' readConfigFile
#' @description reads, parses and performs some validity checks on the configuration data
#' supplied in json format as config file
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param configFile  configFile
#' @import configr
#' @return list of config object containing machineLearningModels, outputDirectory,
#' createStatisticsFile, createPerformancePlots, createPCAPlots
#'
#' @examples
#' \dontrun{readConfigFile(configFile)}

readConfigFile<-function(configFile){

        fileExtension <- tolower(file_ext(configFile))
        if(fileExtension != "json")
                stop("Input parameters validation error: Configuration file format is not supported, json is valid!")

        config <-read.config(file = configFile)


        # checks if the output directory exists
        # Output directory will contain statistics report, pca plots and performance plots
        # generated by the program
        if(!is.null(config$outputDirectory) && !file.exists(config$outputDirectory))
                stop("Input parameters validation error: Output directory does not exist!")

        #if output directory is not provided, working directory is used as an outputDirectory
        if(is.null(config$outputDirectory) || is.na(config$outputDirectory))
                config$outputDirectory = getwd()

        config$outputDirectory = paste0(config$outputDirectory, "/FoodQualityController-", Sys.time())

        # machinelearningmodels are parsed and a vector of machineLearningModels is created in different format
        # each machine leaarning model in the vector becomes string in the format of
        # shortName:pretreatment:numberOfIterations:proportionOfTrainingSet
        mlmConfig <-  config$machineLearningModels
        mlmList <-c()
        for(i in 1:length(mlmConfig$shortName)){
                if( (mlmConfig$shortName[i] == "RT" || mlmConfig$shortName[i] == "RFR")  && (!is.null(mlmConfig$direction[i]) && !is.na(mlmConfig$direction[i])))
                        warning("Data pretreatmet is not performed in Ramdom Forests and Regression Trees, parameter is ignored!")
                if(mlmConfig$shortName[i] != "SR" &&  !is.null(mlmConfig$direction[i]) && !is.na(mlmConfig$direction[i]))
                        warning("direction paremeter is only used in Stepwise Regression, in other regression models it is ignored!")

                if(is.null(mlmConfig$pretreatment[i]) || is.na(mlmConfig$pretreatment[i]))
                        mlmConfig$pretreatment[i] <- "mean-center"
                if(is.null(mlmConfig$numberOfIterations[i]) || is.na(mlmConfig$numberOfIterations[i]))
                        mlmConfig$numberOfIterations[i] <- defNumberOfIterations
                if(is.null(mlmConfig$proportionOfTrainingSet[i]) || is.na(mlmConfig$proportionOfTrainingSet[i]))
                        mlmConfig$proportionOfTrainingSet[i] <- defPercentageForTrainingSet
                 if(is.null(mlmConfig$direction[i]) || is.na(mlmConfig$direction[i]) )
                        mlmConfig$direction[i] <- defDirectionInStepwiseRegression


                mlmList <- c(mlmList, paste0(mlmConfig$shortName[i], ":" , mlmConfig$pretreatment[i], ":",
                                             mlmConfig$numberOfIterations[i], ":" ,mlmConfig$proportionOfTrainingSet[i], ":"))
        }

        config$machineLearningModels <- mlmList

        return(config)
}


#' readDataset
#' @description reads, parses and performs some validity checks on the dataset.
#' Data manipulation is done if it is needed. For example if the number of features exceeds
#' 200, it is reduced by feature selection. Any name of feature is numeric, it is converted to
#' character value as it is required in some machine learning models.
#' supplied in json format as config file
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param dataFileName  dataFileName
#' @import openxlsx caret tools
#' @return dataFrame
#'
#' @examples
#' \dontrun{readConfigFile(configFile)}
#'
readDataset<-function(dataFileName){

        fileExtension <- tolower(file_ext(dataFileName))

        dataSet <- data.frame()
        # According to file extension different method is used to read data
        if(fileExtension == "xlsx")
                dataSet <- openxlsx::read.xlsx(dataFileName, sheet = 1, startRow = 1, rowNames=TRUE)
        if(fileExtension == "csv")
                dataSet<-read.table(dataFileName, sep=",", header=TRUE, row.names=1)

        dataFileName<-"/Users/ozlemkaradeniz/Cranfield/Thesis/data/MSI_beef_air_spoilage_GM_OK.xlsx"

        emptyColumns <- colSums(is.na(dataSet) | dataSet == "") == nrow(dataSet)
        dataSet<-dataSet[, !emptyColumns]

        dataSet <- na.omit(dataSet)

        colnames(dataSet)<-gsub("\\/", "\\.", colnames(dataSet))

        if(any(!is.na(as.numeric(colnames(dataSet)))))
                colnames(dataSet)[colnames(dataSet)!="TVC"] <- paste0("a", colnames(dataSet),"")

         # number of features is reduced by feature selection,
         # import in processing FTIR data
         if(ncol(dataSet) > 200){
                features<- selectFeatures(dataSet)
                dataSet<-dataSet[,c(features,"TVC")]
         }

        return(dataSet)
}

createPerformanceStatistics <- function(performanceResults, regressionParameterList){
        # RMSEList contains list of RMSE for each iteration
        RMSEList <- vector(mode="list", length = regressionParameterList$numberOfIterations)
        RSquareList <- vector(mode="list", length = regressionParameterList$numberOfIterations)

        RMSEList <- unlist(lapply(performanceResults, function(x) x$RMSE))
        meanRMSE <- round(mean(RMSEList), 4)
        cumulativeMeanRMSEList <- cumsum(RMSEList) / seq_along(RMSEList)
        names(cumulativeMeanRMSEList) <- seq_along(RMSEList)

        # RSquareList contains list of RSquare for each iteration
        RSquareList <- unlist(lapply(performanceResults, function(x) x$RSquare))
        meanRSquare <- round(mean(RSquareList), 4)
        cumulativeMeanRSquareList <- cumsum(RSquareList) / seq_along(RSquareList)
        names(cumulativeMeanRSquareList) <- seq_along(RSquareList)

        bestHyperParamsList <- NULL
        if(!is.null(performanceResults[[1]]$bestHyperParams))
                bestHyperParamsList <- unlist(lapply(performanceResults, function(x) x$bestHyperParams))


        regressionParameterList$methodWithDataScaling <- paste0(regressionParameterList$method, "(", regressionParameterList$pretreatment,  ")")

        cat(paste0(regressionParameterList$method, "(", regressionParameterList$pretreatment,  ") mean RMSE: ", meanRMSE, '\n'))
        cat(paste0(regressionParameterList$method, "(", regressionParameterList$pretreatment,  ") mean RSquare: ", meanRSquare, '\n'))

        # Result object is returned to run.regression function in regression.R, which contains whole performance information for the machine learning model
        result <- list("RMSEList"= RMSEList, "cumulativeMeanRMSEList" = cumulativeMeanRMSEList, "RMSE" = meanRMSE,
                       "RSquareList" = RSquareList, "cumulativeMeanRSquareList" = cumulativeMeanRSquareList, "RSquare" = meanRSquare,
                       "bestHyperParamsList" = bestHyperParamsList, method = regressionParameterList$method, platform = regressionParameterList$platform,
                       "pretreatment" = regressionParameterList$pretreatment)
}

#' selectFeatures
#' @description reduces the number of features in the dataset
#' by selecting the more important fautures
#' @author Ozlem Karadeniz \email{ozlem.karadeniz.283@@cranfield.ac.uk}
#' @param  dataSet  dataFrame object
#' @import Boruta
#' @return dataFrame
#'
#' @examples
#' \dontrun{selectFeatures(dataSet)}

selectFeatures<-function(dataSet){

        # Perform Boruta search
        # It uses Rnadomforest model behind,
        # search top-down and eliminates the irrelevant features step-by-step progressively.
        boruta_output <- Boruta(TVC ~ ., data=na.omit(dataSet), doTrace=0)

        boruta_signif <- getSelectedAttributes(boruta_output, withTentative = TRUE)

        return(boruta_signif)
}


