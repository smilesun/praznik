context("test-input.R")

test_that("crazy decision works",{
 data.frame(A=rep(letters[1:2],each=20))->X
 rep(c(TRUE,FALSE),each=20)->Y
 expect_equal(names(MIM(X,Y,1)$selection),"A")
})

test_that("crazy attributes work",{
 badfactor<-factor(c(rep(c("z","a"),each=7),letters))[1:14]
 data.frame(
  bool=rep(c(TRUE,FALSE),each=7),
  int=as.integer(rep(c(-37,33),each=7)),
  badfactor=badfactor
 )->X
 factor(rep(letters[1:2],each=7))->Y
 MIM(X,Y,3)->S
 expect_true(all(names(S$selection)%in%names(X)))
 expect_equal(setNames(S$score,NULL),setNames(rep(S$score[1],3),NULL))
})

test_that("X must be a data.frame",{
 expect_error(MIM(list(1:3),NULL,NULL),"X must be a data.frame")
})

test_that("Nameless data.frames",{
 z<-iris[,-5]
 names(z)<-NULL
 JMI(z,iris$Species,4)->ans
 expect_null(names(ans$score))
 expect_null(names(ans$selection))
 expect_true(all(ans$selection%in%(1:4)))
})

test_that("Constant real features work",{
 #Throws segfault in 1.0.0
 MIM(data.frame(a=rep(1,150)),iris$Species,1)->ans
 expect_equal(names(ans$selection),"a")
 expect_equal(ans$score,c(a=0))
})

test_that("Zero-score features work",{
 expand.grid(a=c(T,F),b=c(T,F),n1=c(T,F),n2=c(T,F),n3=c(T,F))->X
 X$aub<-X$a|X$b
 X$anb<-X$a&X$b
 Y<-X$a!=X$b
 for(e in c(JMI,DISR,MRMR))
  expect_equal(sort(names(e(X,Y,ncol(X))$selection)),sort(names(X)))
 for(e in c(MIM,CMIM,JMIM,NJMIM)){
  e(X,Y,ncol(X))->ans
  expect_true(all(ans$score>0))
  expect_true(all(names(ans$selection)%in%names(X)))
  expect_false(any(duplicated(ans$selection)))
 }
})

test_that("X must be only reals, booleans, integers or factors",{
 Y<-c(TRUE,TRUE,FALSE,FALSE,FALSE)
 li<-data.frame(A=1:5)
 li$A<-list(1,1:2,1:3,1:4,1:5)
 badX<-list(
  char=data.frame(A=letters[1:5],stringsAsFactors=FALSE),
  realna=data.frame(A=c((1:4)*5.5,NA)),
  realinf=data.frame(A=c(1:4,Inf)),
  img=data.frame(A=1:5+3i),
  li=li
 )
 for(X in badX)
  expect_error(MIM(X,Y,1))
})

test_that("NAs and other quirks are caught",{
 Y<-iris$Species; Y[3]<-NA
 X<-iris[,-5]; X[12,3]<-NA
 expect_error(MIM(X,iris$Species,1),"Non-finite numeric values are not allowed")
 X[12,3]<-Inf
 expect_error(MIM(X,iris$Species,1),"Non-finite numeric values are not allowed")
 X[12,3]<-NaN
 expect_error(MIM(X,iris$Species,1),"Non-finite numeric values are not allowed")
 X<-iris[,"Species",drop=FALSE]; X[17,1]<-NA
 expect_error(MIM(X,iris$Species,1),"NA values are not allowed")
 X<-iris[,"Species",drop=FALSE]
 X[,1]<-as.integer(X[,1]); X[17,1]<-NA
 expect_error(MIM(X,iris$Species,1),"NA values are not allowed")
})
