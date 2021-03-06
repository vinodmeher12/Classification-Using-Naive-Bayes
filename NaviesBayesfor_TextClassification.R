#Required Pacakages 
Pacakagelist<-c("tm","wordcloud","e1071","gmodels")
install.packages(Pacakagelist)
library(tm)
library(wordcloud)
library(e1071)
library(gmodels)

# *******************************Part I : filtering mobile phone spam with the naive Bayes algorithm 
# Step 1: Collect Data
sms_raw <- read.csv(file.choose(), header= TRUE, stringsAsFactors = FALSE)  # using sms_spam.csv
str(sms_raw)
dim(sms_raw)

# Turn type column into factors for "ham" and "spam"
sms_raw$type <- factor(sms_raw$type)
str(sms_raw$type)
table(sms_raw$type)
#
# Step 2: Prepare Data
#
# Corpus for tm package of all SMS messages
sms_corpus <- Corpus(VectorSource(sms_raw$text))
print(sms_corpus)
inspect(sms_corpus[1:3])
# Clean/Normalize text
corpus_clean <- tm_map(sms_corpus, tolower)
corpus_clean <- tm_map(corpus_clean, removeNumbers)

corpus_clean <- tm_map(corpus_clean, removeWords, stopwords())
corpus_clean <- tm_map(corpus_clean, removePunctuation)
corpus_clean <- tm_map(corpus_clean, stripWhitespace)
inspect(corpus_clean[1:3])
# Tokenize cleaned text
sms_dtm <- DocumentTermMatrix(corpus_clean)
sms_dtm
inspect(sms_dtm[1:8, 1:8])
# Build training and test data sets

sms_raw_train <- sms_raw[1:4169,]
sms_raw_test <- sms_raw[4170:5559,]

sms_dtm_train <- sms_dtm[1:4169,]
sms_dtm_test <- sms_dtm[4170:5559,]

sms_corpus_train <- corpus_clean[1:4169]
sms_corpus_test <- corpus_clean[4170:5559]

prop.table(table(sms_raw_train$type))
prop.table(table(sms_raw_test$type))

# Visualize tokens with wordcloud

wordcloud(sms_corpus_train, min.freq = 40, random.order = FALSE)

spam <- subset(sms_raw_train, type == "spam")
ham <- subset(sms_raw_train, type == "ham")

wordcloud(spam$text, max.words = 40, scale = c(3, 0.5)) 
wordcloud(ham$text, max.words = 40, scale = c(3, 0.5))

# Frequent terms
sms_dict <- findFreqTerms(sms_dtm_train, 5)
sms_train <- DocumentTermMatrix(sms_corpus_train, list(sms_dict))
sms_test <- DocumentTermMatrix(sms_corpus_test, list(sms_dict))

#check the Sparsity 
review_dtm<-removeSparseTerms(sms_dtm, 0.99)
review_dtm

# custom funtion tranform numeric features
convert_counts <- function(x) {
  x <- ifelse(x > 0, 1, 0)
  x <- factor(x, levels = c(0, 1), labels = c("No", "Yes")) 
  return(x)
}

sms_train <- apply(sms_train, MARGIN = 2, convert_counts) 

sms_test <- apply(sms_test, MARGIN = 2, convert_counts)
sms_test[1,]
#
# Step 3: Train
#


sms_classifier <- naiveBayes(sms_train, sms_raw_train$type)
sms_classifier

#
# Step 4: Evaluate Performance
#
sms_test_pred <- predict(sms_classifier, sms_test)
sms_test_pred
CrossTable(sms_test_pred, sms_raw_test$type,
           prop.chisq = FALSE, prop.t = FALSE,
           dnn = c('predicted', 'actual'))


#
# Step 5: Improve Performance
#
sms_classifier2 <- naiveBayes(sms_train, sms_raw_train$type, laplace = 1)
sms_test_pred2 <- predict(sms_classifier2, sms_test)
CrossTable(sms_test_pred2, sms_raw_test$type,
           prop.chisq = FALSE, prop.t = FALSE, prop.r = FALSE,
           dnn = c('predicted', 'actual'))


#*********************** Part II: Amazon Product reviews prediction (Sentiment Analysis)


# Step 1: Collect Data
Amzaon_raw <- read.csv(file.choose(), stringsAsFactors = FALSE)
str(Amzaon_raw)
dim(Amzaon_raw)

# converting  type column into factors for "postive" and "Negative"
Amzaon_raw$Classr <- factor(Amzaon_raw$Classr, levels = c(1, 0), labels = c("Postive", "Negative"))
str(Amzaon_raw$Classr)
table(Amzaon_raw$Classr)

#
# Step 2: Prepare Data
#
# Corpus for tm package of all  product reviews

Amzaon_corpus <- Corpus(VectorSource(Amzaon_raw$Comments))
print(Amzaon_corpus)
inspect(Amzaon_corpus[1:3])

# Clean/Normalize text
corpus_clean <- tm_map(Amzaon_corpus, tolower)
corpus_clean <- tm_map(corpus_clean, removeNumbers)
#corpus_clean <- tm_map(corpus_clean, removeWords, c(stopwords("english"),"us","unless"))
corpus_clean <- tm_map(corpus_clean, removeWords, stopwords())
corpus_clean <- tm_map(corpus_clean, removePunctuation)
corpus_clean <- tm_map(corpus_clean, stripWhitespace)

inspect(corpus_clean[1:3])
# Tokenize cleaned text
Amzaon_dtm <- DocumentTermMatrix(corpus_clean)
Amzaon_dtm
inspect(Amzaon_dtm[1:8, 1:8])

# Build training and test data sets
set.seed(101)
ind<-sample(2,nrow(Amzaon_raw), replace = TRUE,prob = c(0.7,0.3))

Amzaon_raw_train <- Amzaon_raw[ind==1, ]
Amzaon_raw_test <- Amzaon_raw[ind==2, ]

Amzaon_dtm_train <- Amzaon_dtm[ind==1, ]
Amzaon_dtm_test <- Amzaon_dtm[ind==2, ]

Amzaon_corpus_train <- corpus_clean[ind==1]
Amzaon_corpus_test <- corpus_clean[ind==2]

prop.table(table(Amzaon_raw_train$Classr))
prop.table(table(Amzaon_raw_test$Classr))

# Visualize tokens with wordcloud
wordcloud(Amzaon_corpus_train, min.freq = 10, random.order = FALSE)
Postive <- subset(Amzaon_raw_train, Classr == "Postive") 
Negative <- subset(Amzaon_raw_train, Classr == "Negative")

wordcloud(Postive$Comments, max.words = 10, scale = c(3, 0.5)) 
wordcloud(Negative$Comments, max.words = 10, scale = c(3, 0.5))

# Frequent terms
Amzaon_dict <- findFreqTerms(Amzaon_dtm_train, 2)
Amzaon_train <- DocumentTermMatrix(Amzaon_corpus_train, list(Amzaon_dict))
Amzaon_test <- DocumentTermMatrix(Amzaon_corpus_test, list(Amzaon_dict))

#check the Sparsity 
review_dtm<-removeSparseTerms(Amzaon_dtm, 0.99)
review_dtm

# custom funtion tranform numeric features
convert_counts <- function(x) { 
  x <- ifelse(x > 0, 1, 0) 
  x <- factor(x, levels = c(0, 1), labels = c("No", "Yes")) 
  return(x)
}

Amzaon_train <- apply(Amzaon_train, MARGIN = 2, convert_counts) 
Amzaon_test <- apply(Amzaon_test, MARGIN = 2, convert_counts)
Amzaon_train[1,]
#
# Step 3: Train
#

Amzaon_classifier <- naiveBayes(Amzaon_train, Amzaon_raw_train$Classr)

#
# Step 4: Evaluate Performance
#
Amzaon_test_pred <- predict(Amzaon_classifier, Amzaon_test)
Amzaon_test_pred

CrossTable(Amzaon_test_pred, Amzaon_raw_test$Classr,
           prop.chisq = FALSE, prop.t = FALSE, dnn = c('predicted', 'actual'))

#
# Step 5: Improve Performance
#
Amzaon_classifier2 <- naiveBayes(Amzaon_train, Amzaon_raw_train$Classr,
                                 laplace = 1)

Amzaon_test_pred2 <- predict(Amzaon_classifier2, Amzaon_test)

CrossTable(Amzaon_test_pred2, Amzaon_raw_test$Classr, prop.chisq = FALSE, prop.t = FALSE, prop.r = FALSE, dnn = c('predicted', 'actual'))

