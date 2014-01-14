### grabbing the csv from SCMP

base_url <- "http://widgets.scmp.com/infographic/20140113/policyaddress/data/chi/"

require(plyr)
tsang_text <- ldply(seq(2006, 2012), function(x) { read.csv(paste0(base_url, x, ".all.csv"), stringsAsFactor=FALSE) })[,2]

cy_text <- read.csv(paste0(base_url, "2013", ".all.csv"), stringsAsFactor=FALSE)[,2]

write.csv(tsang_text, file="tsang_text.csv", row.names=FALSE)

write.csv(cy_text, file="cy_text.csv", row.names=FALSE)

### using Python's Jieba to tokenize the text

system("python tokenization.py")

cy_tokenized <- readLines("cy_tokenized.txt")

tsang_tokenized <- readLines("tsang_tokenized.txt")

policytext <- data.frame(text = c(cy_tokenized, tsang_tokenized), speaker = c(rep(1, length(cy_tokenized)), rep(0, length(tsang_tokenized))))

### read in the stopwords,
### extracted from http://www.cnblogs.com/ibook360/archive/2011/11/23/2260397.html, convert to trad chinese with cconv, plus some additional symbols

stopwords <- readLines("hk_stopwords.txt")

require(tm)

policy_corpus <- Corpus(VectorSource(policytext$text))

#policy_corpus <- tm_map(policy_corpus, removeWords, words = stopwords)

tdm <- TermDocumentMatrix(policy_corpus, control=list(wordLengths=c(2, Inf)))
tdm <- removeSparseTerms(tdm, (1155-3)/1155) ### keep terms appear at least thrice

### tm package is buggy. remove the stopwords manually
tdm_m <- as.matrix(tdm)[!dimnames(tdm)[[1]] %in% stopwords,]
tdm_m <- tdm_m[grep("[[:punct:]]", row.names(tdm_m), invert=TRUE), ]
tdm_m <- tdm_m[grep("^[0-9]+$", row.names(tdm_m), invert=TRUE), ]

cal_chisq <- function(n, tdm_m, speaker) {
  twoxtwo <- table(tdm_m[n,] > 0, speaker)
  chisqv <- suppressWarnings(chisq.test(twoxtwo, correct=FALSE)$statistic)
  cy_r <- (twoxtwo[4] + 0.5) / (twoxtwo[3] + twoxtwo[4] + 0.5) 
  tsang_r <- (twoxtwo[2] + 0.5) / (twoxtwo[1] + twoxtwo[2] + 0.5)
  #print(cy_r)
  #print(tsang_r)
  rr <- cy_r / tsang_r
  #print(rr)
  return(data.frame(term = row.names(tdm_m)[n], chisqv = chisqv, rr = rr, stringsAsFactors=FALSE))
}

termschiv <- ldply(1:ncol(tdm_m), cal_chisq, tdm_m = tdm_m, speaker = policytext$speaker)

cy_terms <- termschiv[termschiv$rr > 1,]

topcy_terms <- cy_terms[order(cy_terms$chisqv, decreasing=TRUE),][1:400,]

### not so R's solution

js_array <- c()
for (i in 1:nrow(topcy_terms)) {
  js_array[i] <- paste0('["', topcy_terms[i,1], '", "', round(topcy_terms[i,2] *5 ,3), '"]')
}
cat(readLines("header.txt"), paste(js_array, collapse=" , " ), readLines("footer.txt"), file="CY_terms.html")
