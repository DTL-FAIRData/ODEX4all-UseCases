#### Step 1: Install and load the required packages 
library(httr)
library(jsonlite)
library(tm)
library(tidytext)
library(wordcloud)
library(dplyr)
library(tidytext)
library(quanteda)
library(SnowballC)

setwd("/home/anandgavai/AARestructure/ODEX4all-UseCases/Limagrain/src")
patList<-read.csv("../data/excel2016-06-21-10-09-28.csv",header = TRUE)


#### Step 2a: Load files to create dictionary and clean it 

dic_key<- read.csv("../data/keywords.csv",header=FALSE)
dic_key<-as.character(dic_key[,1])


##### remove leading and training white spaces
dic_key<-trimws(dic_key)

##### remove all special characters and replace them with space
dic_key <- gsub("[[:punct:]]", " ", dic_key)

##### remove \x96 from the character vector
dic_key <- gsub("\\\x96"," ",dic_key)


##### remove \x92 from the character vector
dic_key <- gsub("\\\x92"," ",dic_key)

##### remove \xd7 from the character vector
dic_key <- gsub("\\\xd7"," ",dic_key)


##### make dictionary of crop ontologies
dic_CO<-read.csv("CO_322.csv",header=TRUE)
dic_CO<-c(as.character(dic_CO$Trait.name),as.character(dic_CO$Attribute))

##### select only unique terms
dic_CO<-unique(dic_CO)


##### Combined dictionary keywords + CO terms 
dic_CO_Key<-c(dic_key,dic_CO)



##### I create dictionary from title terms DWPI
title<-as.character(patList$Title...DWPI)
ll<-NULL
for(i in 1:length(title)){
  ll<-c(ll,unlist(strsplit(title[i]," ")))   
}

##### Combined dictionary keywords + CO terms + Title terms
dic_CO_key_title<-c(dic_CO_Key,ll)
dic_CO_key_title<-unique(gsub(",","",dic_CO_key_title))
dic_CO_key_title<-unique(gsub(";","",dic_CO_key_title))
dic_CO_key_title<-unique(gsub("\\(e.g.","",dic_CO_key_title))
dic_CO_key_title<-unique(gsub("e.g.","",dic_CO_key_title))
dic_CO_key_title<-unique(gsub("/its","",dic_CO_key_title))
dic_CO_key_title<-unique(gsub("\\(","",dic_CO_key_title))
dic_CO_key_title<-unique(gsub("\\)","",dic_CO_key_title))
dic_CO_key_title<-dic_CO_key_title[dic_CO_key_title != ""]

##### returns string w/o leading or trailing whitespace
trim <- function (x) gsub("^\\s+|\\s+$", "", x)
dic_CO_key_title<-trim(dic_CO_key_title)


##### transform to lower and get unique set of terms
dic_CO_key_title<-unique(tolower(dic_CO_key_title))

#write.csv(dic_CO_key_title,file="dic_CO__key_title.csv")
# do processing in Open Refine by removing all special characters and numbers. 
# These steps are documented in the JSON Object created by OpenRefine  

dic_CO_key_title<- read.csv("dictionary_CO_Title_Key_From_OpenRefine.csv",header=FALSE)
dic_CO_key_title<- as.character(dic_CO_key_title[,1])
dic_CO_key_title<- unique(dic_CO_key_title)

##### create key value pair 
val<-dic_CO_key_title
key<-gsub(" ","_",val)
dd<-cbind(key,val)
rownames(dd)<-dd[,1]
dd<-dd[,2]

##### create a key value pair to make dictionary
dfd<-dictionary(dd)

##### Dump of the dictionary consisting of keywords list, Crop Ontology terms and Title terms DWPI
print(dic_CO_key_title)


#### Step 3: Create corpus here with multi-word dictionary terms
abst_dwpi<- as.character(patList$Abstract...DWPI)

abst_dwpi <- phrasetotoken(abst_dwpi, dfd)

mydfm <- dfm(abst_dwpi)


#### Data Transformation
#### now keep only the keywords from the dictionary ignoring frequent words occuring in the corpus
mydfm<-as_data_frame(mydfm)
dtm_tib<-mydfm[,which((colnames(mydfm)%in%key))]


#### remove stop words from "english"
dtm_tib<-dtm_tib[,which(!(colnames(dtm_tib)%in%stopwords("english")))]


#### assign document names to the DocumentTermMatrix
rownames(dtm_tib)<- as.character(patList$Publication.Number)



#### data transformation
dfm<-as.dfm(dtm_tib)
dtm<-as.DocumentTermMatrix(dfm)


##### remove terms that occure in only 0.1% of all documents (in short less common words)
dtm<-removeSparseTerms(dtm, 0.99) # this is tunable 0.6 appears to be optimal


##### Get selected metadata information
dfm<-as.matrix(dtm)

meta<-patList[,c("Publication.Number","Title","Publication.Date","Assignee.Applicant","Inventor","Priority.Date...Earliest")]
rownames(meta)<-meta[,1]
dtm<-merge(dfm,meta,by="row.names")

### rearrange columnnames for metadata
dtm<-dtm[,c(901:906,1:900)]

write.csv(as.matrix(dtm),file="dtm_Abstracts_dwpi_CO_Key_Title.csv")

#### Data Validation Code
#### Check for term "dna_extraction"
#as.matrix(dtm[,"dna_extraction"])


#### it occurs 1's in document "US20150191771A1" and 3's in document "WO2013119962A1" 3's in document US20130210006A1


##### create term frequency
#termFreq <- colSums(as.matrix(dtm))
#head(termFreq)

#tf <- data.frame(term = names(termFreq), freq = termFreq)
#tf <- tf[order(-tf[,2]),]
#head(tf)




#### Step 5: Visualize word cloud of terms

#set.seed(1234)
#wordcloud(words = tf$term, freq = tf$freq, min.freq = 1,
#          max.words=8000, random.order=FALSE, rot.per=0.35, 
#          colors=brewer.pal(8, "Dark2"))



#### Step 6 : Explore frequent terms and their associations

##### frequent terms
#findFreqTerms(dtm, lowfreq = 3)


##### frequent associations
#findAssocs(dtm, terms = "dna_extraction", corlimit = 0.3)


##### plot word frequency
#d<-barplot(tf[1:10,]$freq, las = 2, names.arg = tf[1:10,]$term,
           col ="lightblue", main ="Most frequent words",
           ylab = "Word frequencies")



# to do intersect with dictionary 

## Find terms that occure atleast 5 times or more
## findFreqTerms(dtm_abst, 5)


### find associations for a given term for example "germplasm"
## findAssocs(dtm_abst, "germplasm", 0.5)



