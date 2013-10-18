
require(RandomFields)


setwd(getwd()) # Chemin à indiquer correctement


files <- list.files(pattern = "\\.txt$")
for(i in 1:length(files)){
  print(i)
  print(substr(files[i], 1, 12))
  if(substr(files[i], 1, 12)=="inputFileCPU"){
    Inputfile=files[i]
    break
  }
}

dataInput=read.table( Inputfile,  sep="")

for(i in 1:dim(dataInput)[2]){
	print(i)
  if(dataInput[1,i]=="SR"){
  	print("SR")
    param <- c(25, 25, 0, 10)} # mean, variance, nugget, scale(range)
  else if(dataInput[1,i]=="IR"){
  	  	print("IR")
    param <- c(25, 25, 0, 50)
  }
  else if(dataInput[1,i]=="LR"){
  	  	print("LR")
    param <- c(25, 25, 0, 100)
  }
  
  model <- "spherical"
  RFparameters(PracticalRange=FALSE)
  p <- 1:10
  field <- GaussRF(x=p, y=p, grid=TRUE, model=model, param=param)
  
  # another grid, where values are to be simulated
  step <- 1 # or 0.3
  x <- seq(0, 199, step)
  # standardisation of the output
  
  
  #conditional simulation
  krige.method <- "O" ## random field assumption corresponding to
  ## those of ordinary kriging
  
  cz <- CondSimu(krige.method, x, x, grid=TRUE,
                 model=model, param=param,
                 given=expand.grid(p,p),# if data are given on a grid
                 # then expand the grid first
                 data=field)
  
  nameOutput=paste("RandField_", dataInput[1,i],"_No",i,".csv", sep = "")
  write.table(cz,file=nameOutput,sep=",",row.names=F, col.names=F) 
}
