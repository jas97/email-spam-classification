# Set the working directory
setwd("D:/Fax/Winter 2019 - 2020/Statistical Principles of Data Science/Homework/Homework 4/")

# loading data
ds <- read.table("spambase.csv", header=FALSE, sep=",",col.names = readLines("names.csv"))

# importing necessary libraries
install.packages('caret')
library(caret) 
install.packages('ggplot2')
library(ggplot2)
install.packages("class")
library(class)
install.packages("devtools")
library(devtools)
install.packages("e1071")
install.packages("plsgenomics")
packageurl <- "https://cran.r-project.org/src/contrib/Archive/KODAMA/KODAMA_0.0.1.tar.gz"
install.packages(packageurl, repos=NULL, type="source")
library(KODAMA)
install.packages("tree")
library(tree)

# examining the dataset
dim(ds)
head(ds)
summary(ds)

# checking proportion of spam mail
prop.spam <- sum(ds$spam) / dim(ds)[1]
print(paste(round(prop.spam * 100, 2), "% of emails in the data set are spam."))

# plotting proportion of spam and not spam emails
ggplot(ds, aes(factor(x=spam))) +
  geom_bar(stat="count", fill=c("red", "blue"), alpha=0.4) + 
  xlab("Spam/Not spam") +
  scale_x_discrete(labels= c("Not spam", "Spam"))

# splitting the data set into test and train
# setting seed to make results reproducible
set.seed(2) 
num.train <- floor(0.7 * nrow(ds))
train.samples <- sample.int(n = nrow(ds), size = num.train, replace = FALSE)
test.samples <- seq(1:nrow(ds))[-train.samples]

train.num <- length(train.samples)
test.num <- length(test.samples)

# setting class variable to be a factor
ds[, ncol(ds)] = as.factor(ds[, ncol(ds)])

# --------------
# Classification
# --------------

# features 
ds.features <- ds[, 1:ncol(ds)-1]
# labels
ds.labels <- ds[, ncol(ds)]

# ---------------------------------
# Attemp 1 - Default knn with k = 1
# ---------------------------------

# let's try default R's knn without any modifications of parameters or data
dist.eucl <- knn.dist(ds.features, dist.meth = 'euclidean')
knn.default <- knn.predict(train.samples, test.samples, y=ds.labels, dist.matrix=dist.eucl, k=1)

# checking accuracy on test set
print(paste("Accuracy on test set for knn.default = ", 
            sum(knn.default == ds[test.samples,]$spam)/test.num))

# confusion matrix
confusionMatrix(factor(knn.default), ds[test.samples,]$spam)

# -------------------------------------
# Approach 2: Changing distance measure
# -------------------------------------

# ------------------
# Manhattan distance
# ------------------
dist.manh <- knn.dist(ds.features, dist.meth='manhattan')
knn.manh.1 <- knn.predict(train.samples, test.samples, ds.labels, dist.manh, k=1)
print(paste("Accuracy on test set for knn.manh.1 = ", 
            sum(knn.manh.1 == factor(ds[test.samples,]$spam))/test.num))

#confusion matrix
confusionMatrix(factor(knn.manh.1), ds[test.samples,]$spam)

# ------------------
# Maximum distance 
# ------------------
dist.max <- knn.dist(ds.features, dist.meth='maximum')
knn.max.1 <- knn.predict(train.samples, test.samples, ds.labels, dist.max, k=1)
print(paste("Accuracy on test set for knn.max.1 = ", 
            sum(knn.max.1 == factor(ds[test.samples,]$spam))/test.num))
# confusion matrix
confusionMatrix(factor(knn.max.1), ds[test.samples,]$spam)


# -----------------------------------
# Attempt 3 : Standardizing variables
# -----------------------------------

ds[, 1:(ncol(ds)-1)]<- scale(ds[, 1:(ncol(ds)-1)], center=TRUE, scale=TRUE)
ds.features.stand <- ds[, 1:(ncol(ds) - 1)]
dist.eucl.stand <- knn.dist(ds.features.stand)
knn.stand.1 <- knn.predict(train.samples, test.samples, ds.labels, dist.eucl.stand, k=1)
print(paste("Accuracy on test set for knn.stand.1 = ", 
            sum(knn.stand.1 == factor(ds[test.samples,]$spam))/test.num))

# confusion matrix
confusionMatrix(factor(knn.stand.1), ds[test.samples,]$spam)


# ----------------------------
# Attempt 4: Feature selection
# ----------------------------


# Predicting only based on the features regarding 
# the capital sequence in the email
# Columns[55:57]

capital.features <- ds[, 55:57]
dist.eucl.capital <- knn.dist(capital.features)
knn.capital.1 <- knn.predict(train.samples, test.samples, ds.labels, dist.eucl.capital, k=1)
print(paste("Accuracy on test set for knn.capital.1 = ", 
            sum(knn.capital.1 == ds[test.samples,]$spam)/test.num))
confusionMatrix(factor(knn.capital.1), ds[test.samples,]$spam)

# Predicting based only on words 
# Columns[1:48]
word.features <- ds[, 1:48]
dist.eucl.word <- knn.dist(word.features)
knn.words.1 <- knn.predict(train.samples, test.samples, ds.labels, dist.eucl.word, k=1)
print(paste("Accuracy on test set for knn.words.1 = ", 
            sum(knn.words.1 == ds[test.samples,]$spam)/test.num))

confusionMatrix(factor(knn.words.1), ds[test.samples,]$spam)

# Predicting based on words and capital sequences
# excluding features regarding characters (Columns[49:54])
word.cap.features <- ds[, -seq(49, 54, by=1)]
dist.eucl.word.cap <- knn.dist(word.cap.features)
knn.word.cap.1 <- knn.predict(train.samples, test.samples, ds.labels, dist.eucl.word.cap, k=1)
print(paste("Accuracy on test set for knn.word.cap.1 = ", 
            sum(knn.word.cap.1 == factor(ds[test.samples,]$spam))/test.num))

confusionMatrix(factor(knn.word.cap.1), ds[test.samples,]$spam)

# --------------------
# Attempt 5: Varying k
# --------------------

# On the features that contain words and capital
# letter sequences we will vary the k and also 
# the distance measure

k <- c(1, 3, 5, 10)
dist.measures <- c("euclidean", "maximum", "manhattan")
accuracies <- matrix(0, nrow=length(k), ncol=length(dist.measures))

for (i in seq(1, length(k), by=1)) {
  for (j in seq(1, length(dist.measures), by=1)) {
    dist <- knn.dist(word.cap.features, dist.meth = dist.measures[j])
    pred <- knn.predict(train.samples, test.samples, ds.labels, dist, k=k[i])
    correct <- sum(pred == factor(ds[test.samples, ]$spam)) / test.num
    accuracies[i, j] <- correct
  }
}

# printing accuracies
for (i in seq(1, length(k), by=1)) {
  for (j in seq(1, length(dist.measures), by=1)) {
    print(paste("Accuracy for knn with k=", k[i], "and distance measure ",
          dist.measures[j], " = ", accuracies[i,j]))
  }
}

 
## TODO: Napravi spam da bude factor
## TODO: Da tree vuce originalne neskalirane podatke

# ---------------------------------------
# Trying different classification methods
# ---------------------------------------


# Decision trees


tree.spam <- tree(as.factor(spam)~. , data=ds)
summary(tree.spam)

# Visualizing tree
plot(tree.spam)
text(tree.spam, pretty=0)

# Tree accuracy
pred.tree <- predict(tree.spam, ds[test.samples,], type="class")
print(paste("Accuracy with tree = ", sum(pred.tree==as.factor(ds[test.samples,]$spam))/test.num))


# Naive Bayes
bayes <- naiveBayes(as.factor(spam)~. , data=ds)
summary(bayes)

# Naive Bayes accuracy 
pred.bayes <- predict(bayes, ds[test.samples, ])
print(paste("Accuracy with Naive Bayes = ",
            sum(pred.bayes==as.factor(ds[test.samples, ]$spam))/test.num))
