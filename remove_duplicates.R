library(tidyverse)

#Read in the csv that contains all citations, save as df 
#  ./ tells read_csv to look in the working directory

df<-read_csv("./all_citations.csv")

#Rename and reorder some of the columns, save again as df
# everything() just includes everything that is leftover
#Arrange the df in alphabetical order by title_np

df<-select(df, count="Count (Sorted to Title)", Title, title_np = "Title (without punctuation)_R", Duplicate_SL, Duplicate_AK, pub="Publication Title", Pages, abstract="Abstract Note", Author, everything())
df<- arrange(df, title_np)

#Remove all punctuation, spaces, and capitalization from the specified column (title, publication name, and page numbers), makes new column with ns for "no spaces"

df$title_ns<- str_remove_all(df$Title, "[^[:alnum:]]") %>% str_to_lower()
df$pub_ns<- str_remove_all(df$pub, "[^[:alnum:]]") %>% str_to_lower()
df$pages_ns<- str_remove_all(df$Pages, "[^[:alnum:]]") %>% str_to_lower()

#Make new data frames with duplicates removed
#df_1 removes any row that is a duplicate based only on title matching (we are cautious of these because it maybe be too liberal)
#df_2 removes any row that is a duplicate based both on title and page numbers matching
#df_3 removes any row that is a duplicate based both on title and publication name matching

df_1<- distinct(df, title_ns, .keep_all = TRUE)
df_2<- distinct(df, title_ns, pages_ns, .keep_all = TRUE)
df_3<- distinct(df, title_ns, pub_ns, .keep_all = TRUE)

#Combine df_2 and df_3, keeping only the rows that are present in both of them
#This means that df_page_or_pub does not contain any rows that have the same title and page numbers or title and publication name as another row

df_page_or_pub<-inner_join(df_2, df_3)

#Create a data frame (df_anti1) that only contains the rows that match another row on title but have a different publication name and page_numbers, it then creates a new column called "review" that marks each with a 1
#THESE ARE THE ONES THAT MAY BE FALSE DUPLICATES AND NEED TO BE REVIEWED BY HAND

df_anti1<- anti_join(df_page_or_pub, df_1)
df_anti1$review<- rep(1,nrow(df_anti1))

#Create a new column called "def_duplicate" that marks all rows we are confident are duplicates

df_anti2<- anti_join(df, df_page_or_pub)
df_anti2$def_duplicate<- rep(1,nrow(df_anti2))

#Combines the data frame back together, now with "def_duplicate" and "review" column
#The number of rows in this data frame should match your original all_citations.csv file

df_review<- bind_rows(df_anti2, df_anti1, df_1)

#Order the rows based on the titles in alphabetical order, reorder the columns so your new columns are up front for easy finding

df_review<- arrange(df_review, title_np)
df_review<-select(df_review, count, Title, title_np, Duplicate_SL, Duplicate_AK, review, def_duplicate, pub, Pages, abstract, Author, everything())

#Save the new data frame with duplicates and rows needing review marked and all na left blank
#Saves to the working directory
#Use write_excel_csv() not write_csv() because excel will do silly things with a normal csv

write_excel_csv(df_review, file = "./r_review_dupes.csv", na = '')

