int *convertSEXP(struct ht *ht,int n,SEXP in,int *nout){
 int lc=length(getAttrib(in,R_LevelsSymbol)),*out;
 if(isFactor(in) && lc<n){
  //Well-behaving factor; user shall give us such for optimal performance
  *nout=lc;
  out=INTEGER(in);
  for(int e=0;e<n;e++)
   if(out[e]==NA_INTEGER) error("NA values are not allowed");
  return(out);
 }
 if(isFactor(in)||isLogical(in)||isInteger(in)){
  //Integer-alike which needs collapsing into 1..n_levels
  int *out=(int*)R_alloc(sizeof(int),n);
  *nout=fillHtOne(ht,n,INTEGER(in),out,1);
  return(out);
 }
 if(isReal(in)){
  //Magically make discrete by scattering into 10-bins
  double *x=REAL(in),min=INFINITY,max=-INFINITY;
  for(int e=0;e<n;e++){
   if(!R_FINITE(x[e])) error("Non-finite numeric values are not allowed");
   min=min<x[e]?min:x[e];
   max=max>x[e]?max:x[e];
  }
  int *out=(int*)R_alloc(sizeof(int),n);
  if(max==min){
   //Real value is almost constant
   *nout=1;
   for(int e=0;e<n;e++)
    out[e]=1;
   return(out);
  }
  if(n<6){
   *nout=2;
  }else if(n>30){
   *nout=10;
  }else{
   *nout=n/3;
  }
  for(int e=0;e<n;e++)
   out[e]=((int)((x[e]-min)/(max-min)*(double)(*nout)))%(*nout)+1;
  return(out);
 }
 //Other stuff
 return(NULL);
}

void prepareInput(SEXP X,SEXP Y,SEXP K,struct ht **ht,int *n,int *m,int *k,int **y,int *ny,int ***x,int **nx,int nt){
 if(!isFrame(X)) error("X must be a data.frame");
 *n=length(Y);
 *k=INTEGER(K)[0];
 *m=length(X);

 if(*k>*m) error("Parameter k must be at most the number of attributes");
 if(*k<1) error("Parameter k must be positive");
 if(n[0]>2147483648) error("Only at most 2^31 (2.1 billion) objects allowed");
 //TODO: Also eat matrices? --> then fix it
 if(*n!=length(VECTOR_ELT(X,0))) error("X and Y size mismatch");

 for(int e=0;e<nt;e++)
  ht[e]=R_allocHt(*n);

 *y=convertSEXP(*ht,*n,Y,ny);
 if(!*y) error("Wrong Y type");
 
 *nx=(int*)R_alloc(sizeof(int),*m);
 *x=(int**)R_alloc(sizeof(int*),*m);
 for(int e=0;e<*m;e++){
  SEXP XX;
  PROTECT(XX=VECTOR_ELT(X,e));
  (*x)[e]=convertSEXP(*ht,*n,XX,(*nx)+e);
  if(!(*x)[e]) error("Wrong X[,%d] type",e+1);
  UNPROTECT(1);
 }
}

void static inline initialMiScan(struct ht **hta,int n,int m,int *y,int ny,int **x,int *nx,int **_cY,int **_cX,double *_mi,double *bs,int *bi,int nt){
 int *cXc=(int*)R_alloc(sizeof(int),n*nt); if(_cX) *_cX=cXc;
 int *cYc=(int*)R_alloc(sizeof(int),n*nt); if(_cY) *_cY=cYc;

 #pragma omp parallel 
 {
  double tbs=0.;
  int tn=omp_get_thread_num(),*cX=cXc+(tn*n),*cY=cYc+(tn*n),madeCy=0,tbi=-1;
  struct ht *ht=hta[tn]; 
  #pragma omp for
  for(int e=0;e<m;e++){
   fillHt(ht,n,ny,y,nx[e],x[e],NULL,madeCy?NULL:cY,cX,0); madeCy=1;
   double mi=miHt(ht,cY,cX); _mi?_mi[e]=mi:0;
   if(mi>tbs){
    tbs=mi; tbi=e;
   }
  }
  #pragma omp critical
  if(tbs>*bs){
   *bs=tbs;
   *bi=tbi;
  }
 }
}

SEXP makeAns(int k,double **score,int **idx){
 SEXP Ans; PROTECT(Ans=allocVector(VECSXP,2));
 SEXP AnsN; PROTECT(AnsN=allocVector(STRSXP,2));
 SEXP Idx; PROTECT(Idx=allocVector(INTSXP,k));
 SEXP Score; PROTECT(Score=allocVector(REALSXP,k));

 SET_STRING_ELT(AnsN,0,mkChar("selection"));
 SET_STRING_ELT(AnsN,1,mkChar("score"));
 setAttrib(Ans,R_NamesSymbol,AnsN);
 
 SET_VECTOR_ELT(Ans,0,Idx);
 SET_VECTOR_ELT(Ans,1,Score);

 if(score) *score=REAL(Score);
 if(idx) *idx=INTEGER(Idx);
 UNPROTECT(4);
 return(Ans);
}

SEXP finishAns(int k,SEXP Ans,SEXP X){
 if(k<length(VECTOR_ELT(Ans,0))){
  //Need to clip Ans
  SEXP Iidx; PROTECT(Iidx=allocVector(INTSXP,k));
  SEXP Sscore; PROTECT(Sscore=allocVector(REALSXP,k));
  int *idx=INTEGER(VECTOR_ELT(Ans,0)),*iidx=INTEGER(Iidx);
  double *score=REAL(VECTOR_ELT(Ans,1)),*sscore=REAL(Sscore);
  for(int e=0;e<k;e++){
   sscore[e]=score[e];
   iidx[e]=idx[e];
  }
  SET_VECTOR_ELT(Ans,0,Iidx);
  SET_VECTOR_ELT(Ans,1,Sscore);
  UNPROTECT(2);
 }
 //X is a data.frame, does it have names?
 SEXP Xn=getAttrib(X,R_NamesSymbol);
 if(!isNull(Xn)){
  //Copy names into names of scores and selection
  SEXP An; PROTECT(An=allocVector(STRSXP,k));
  int *idx=INTEGER(VECTOR_ELT(Ans,0));
  for(int e=0;e<k;e++){
   SET_STRING_ELT(An,e,STRING_ELT(Xn,idx[e]-1));
  }
  setAttrib(VECTOR_ELT(Ans,0),R_NamesSymbol,An);
  setAttrib(VECTOR_ELT(Ans,1),R_NamesSymbol,An);
  UNPROTECT(1);
 }
 return(Ans);
}

//Macros

#define ISWAP(x,y) do{int *__tmp=x;x=y;y=__tmp;}while(0)
#define EPS 1e-10
