library("RPostgres")

homedata <- "/var/www/data"
analysisdir =NULL
fpath = NULL

setContentType("text/html")

cat('
<!DOCTYPE html>
<html>
<head>
<title>University of Arizona SRP-DMAC Olympus server</title>
<meta http-equiv="expires"; content="0"; charset=UTF-8">
<link rel="stylesheet" type="text/css" href="/AresC/semantic.min.css">
<style>

div#banner2 { 
z-index: 6;

  overflow: hidden;
  position: fixed;
  bottom: 50px;
  left: 0;	
	background-color: #000000;
	width: 100%; 
	height: 3px;
}


div#footnotebanner { 
z-index: 6;

  overflow: hidden;
  position: fixed;
  bottom: 0;
  left: 0;	
	background-color: #FFFFFF;
	width: 100%; 
	height: 50px;
}

#SRPlogo{ 

  overflow: hidden;
  position: fixed;
bottom: 5px;

margin-left:45%;
height: 40px;

}

#NIEHSlogo{

  overflow: hidden;
  position: fixed;
bottom: 5px;

margin-left:5.4%;
height: 40px;


}


div#footnote3 { 
 position: fixed;
       width: auto;
margin-left:78%;   
       float left;
}



</style>

</head>


<body>

<div id="root">
<div class="App">
	<header class="App-header">
	<div class="ui inverted top fixed menu" style:"width:90%">
		<div class="ui container">
		<a class="header item" href="http://dmac.pharmacy.arizona.edu/Ares/Home">
		<h1 >Ares</h1>
		</a>
		<a class="item" href="http://dmac.pharmacy.arizona.edu">
		<h4 > Home</h4>
		</a>
		<a href="https://dmac.pharmacy.arizona.edu/Ares/redirect_uri?logout=https://dmac.pharmacy.arizona.edu" class="item">
		<h4>Logout</h4>
		</a>		
			<div class="ui float right dropdown link item">
   		 		<span class="text">Menu</span>
    					<div class="menu">    
      						<a class="item" href="http://dmac.pharmacy.arizona.edu"> Home </a>
      						<a class="item" href="http://dmac.pharmacy.arizona.edu/Ares/Home"> Ares </a>
						<a class="item" href="https://dmac.pharmacy.arizona.edu/Ares/About/AresAbout.html"> About Ares </a>       							
					</div>
			</div>
		</div>

	</div>
	</header>

<img class="ui centered medium image"  src="/AresC/AresLogo.jpg" style = "padding-top: 100px;">
<div class="ui container appBody" style = "padding-top: 40px;">
')


headconv <- read.csv("/var/www/Rfiles/headconversion.csv")

usremail <- SERVER$headers_in$OIDC_CLAIM_email

username <- headconv$Folder[headconv$Email==usremail]

Aperm <- headconv$Ares[headconv$Email==usremail]

flaguser = 0

if(length(username) != 0){
if(Aperm == 1){
datadirectories <- list.dirs(path = homedata, full.names = FALSE, recursive = FALSE)

for(datadirs in datadirectories){

if(username == datadirs){

flaguser = 1
fpath = paste0("/var/www/data/", username, "/Ares/Data")
}

}
}
}
if(flaguser == 1){


cat('
	<div class="ui container" >
		<p class="p-t-15" style = "font-size: large;">
		Select at least three files for DESeq2 analysis with at least one in each group.</p>
		<div class="ui action input" > <form method="GET">
  		<input type="text" name="gid" id="filter" placeholder="Filter..." style = "height: 34px; border-radius: 5px;" maxlength="30" oninput ="filterchange()">
  		<button class="ui button">Filter</button>
		<button  name="reset" class="ui button">Reset</button>
		</div>')


filenames = list.files(path = fpath)

if(!is.null(GET$gid)){
filenames = list.files(path = fpath ,pattern=GET$gid)
seh = GET$gid
}

if(!is.null(GET$reset)){
filenames = list.files(path = fpath)
GET$gid <- NULL
}
                                                   
cat('
	
			<div class="ui segment">	
			<div class="table-container" style="padding-top: 20px; height:350px;overflow-y: scroll;">
			<table class="ui very basic table">
				<thead class="">
				<tr class="">
				<th class="">
				Name</th>
				<th class="">
				Size</th>
				<th class="">
				Last Modified</th>
				<th class="" style="text-align: center;">
				Group 1
				</th>
				<th class="" style="text-align: center;">
				Group 2
				</th>
				
				</tr>
				
				</thead>

				<tbody class="">')
if (length(list.files(path = fpath ,pattern=GET$gid)) != 0){				
	for(i in 1:length(filenames)){
	cat('
				<tr class="" >
				<td class="">')
	cat(filenames[i])
	cat('</td>
				<td class="">') 
	cat(paste0(round(file.size(file.path(fpath, filenames[i]))/1000))," KB")
	cat('</td>
				<td class="">') 
	cat(as.character(file.mtime(file.path(fpath, filenames[i]))))
	cat('</td>
				<td class="" style="text-align: center;"> <input type="checkbox" id="id') 
cat(i)
  cat('" name="fileA')
  cat(i)
  cat('" value="')
  cat(filenames[i])
  cat('"></td>
				<td class="" style="text-align: center;"> <input type="checkbox" id="id')
cat(i)
  cat('" name="fileB')
  cat(i)
  cat('" value="')
  cat(filenames[i])
  cat('"></td>

				</tr>')
}
}

				cat('</tbody>
				</table>
		</div>
</div>
		
		<div class="m-t-25" style = "padding-top: 20px;">
			<button class="ui black button" name=SubmitAnalysis>
			Submit Analysis</button>
		</div>')

if(!is.null(GET)){

j=1
fn=c()
condition = c()
type = c()

metafold = NULL
tempmeta = matrix(, nrow = 1, ncol = 2)

for( i in names(GET)){

if(substring(i, 1, nchar('file')) == 'file' ){
if(substring(i,5,5) == 'A'){
tempmeta[1,1] = 'Treatment'
condition[j] = 'Treatment'
type[j] = 'singleEnd'
}
if(substring(i,5,5) == 'B'){
tempmeta[1,1] = 'Control'
condition[j] = 'Control'
type[j] = 'singleEnd'
}
fn[j] = GET[[i]]
tempmeta[1,2] = fn[j]
metafold <- rbind(metafold,tempmeta)
j=j+1
}

}



if(!is.null(fn) & length(unique(fn)) != length(fn)){

print('Cannot Pick Same File For Treatment and Control')
}

if(!is.null(condition) & length(unique(condition)) != 2){

print('Must Pick atleast one Treatment and Control')
}

if(!is.null(condition) & length(condition) < 3){

print('Must Pick atleast three three total files')
}


if(grepl("SubmitAnalysis",names(GET)[length(GET)],fixed = TRUE) & !is.null(fn) & !is.null(condition) & length(unique(fn)) == length(fn) & length(unique(condition)) == 2 & length(condition) >= 3){

usedb <- NULL
usedb$app <- "Ares"
usedb$username <- SERVER$headers_in$OIDC_CLAIM_preferred_username

usedb <- as.data.frame(usedb)

con <- dbConnect(RPostgres::Postgres())

dbWriteTable(con, "table1u", value = usedb, append = TRUE, row.names = FALSE)

dbDisconnect(con)


coldata = cbind(condition, type)

a <- read.delim2(file.path(fpath,fn[1]) , quote="", sep="\t", head=F)
ct <- matrix(0, nrow=nrow(a), ncol=length(fn))
rownames(ct) <- as.character(a[, "V1"])
colnames(ct) <- fn

for (i in 1:length(fn)){
  a <- read.delim2(file.path(fpath,fn[i]), quote="", sep="\t", head=F)
ct[,fn[i]] <- as.integer(a[, "V2"])
}

ct <- ct[5:nrow(ct),]

ct <- ct[which(rowSums(ct) > 10),]
dds <- DESeqDataSetFromMatrix(countData = ct,colData = coldata, design = ~ condition)
ddsR <- DESeq(dds)
res <- results(ddsR)

res2 <-na.omit(res)

out.data <- data.frame("Log2FoldChange" = res2$log2FoldChange, "Log10padj" =-log10(res2$padj), "BaseMean" = log10(res2$baseMean), "GeneName"=row.names(res2), "pvalueadj" = res2$padj)
res.data <- data.frame("Log2FoldChange" = res2$log2FoldChange, "Log10padj" =-log10(res2$padj), "BaseMean" = log10(res2$baseMean), "GeneName"=row.names(res2), "Infinity" = 19)
res.data$Infinity[is.infinite(res.data$Log10padj)] = 17
res.data$Log10padj[res.data$Infinity==17] = 1.1*max(res.data$Log10padj[res.data$Infinity == 19])

res.data$MeanBin=as.numeric(cut(res.data$BaseMean, breaks =10))
colfunc <- colorRampPalette(c("blue","red"))
CLabel <- c(paste(0),paste(round(median(res2$baseMean))),paste(round(quantile(res2$baseMean,.9))))
Xran = max(res.data$Log2FoldChange) - min(res.data$Log2FoldChange)

res.data2 <- res.data
res.data2$BaseMean <- res2$baseMean
res.data2 <- subset(res.data2, select = -c(Infinity,MeanBin) )
plotfile <- tempfile(fileext = ".svg")
svg(plotfile, width = 9, height = 6)
par(mar =  c(5, 5, 4, 15) + 0.1)

if(max(res.data$Log10padj)>1.5){
plot(res.data$Log2FoldChange,res.data$Log10padj, col = colfunc(10)[res.data$MeanBin],pch=res.data$Infinity, main="DESeq2 (Group One - Group Two)", ylab="-Log10(padj)", xlab="Log2(Fold Change)",cex.lab=1.5, cex.main=1.5)
abline(h=1.3,lty=2)

legend("topright", inset=c(-.5,0), legend=c("-Log10(padj) = Infinity", "",  "P-value = 0.05"), pch=c(17,NA,NA), lty=c(0,0,2), xpd=TRUE,cex=1)
legend("topright", inset=c(-.4,.25),legend=c("Base Mean"),xpd=TRUE, bty = 'n',cex=1.5)

color.legend(max(res.data$Log2FoldChange)+.25*Xran,.1*max(res.data$Log10padj),max(res.data$Log2FoldChange) +.45*Xran,.6*max(res.data$Log10padj),CLabel,colfunc(10),gradient="y",cex=1.5)
}

else{
plot(res.data$Log2FoldChange,res.data$Log10padj, col = colfunc(10)[res.data$MeanBin],pch=res.data$Infinity, main="DESeq2 (Group One - Group Two)", ylab="-Log10(padj)", xlab="Log2(Fold Change)",ylim=c(0,2),cex.lab=1.5, cex.main=1.5)

abline(h=1.3,lty=2)

legend("topright", inset=c(-.5,0), legend=c("-Log10(padj) = Infinity", "",  "P-value = 0.05"), pch=c(17,NA,NA), lty=c(0,0,2), xpd=TRUE,cex=1.5)
legend("topright", inset=c(-.4,.25),legend=c("Base Mean"),xpd=TRUE, bty = 'n',cex=1.5)

color.legend(max(res.data$Log2FoldChange)+.25*Xran,.25,max(res.data$Log2FoldChange)+.45*Xran,1.25,CLabel,colfunc(10),gradient="y",cex=1.5)

}


dev.off()

randbase = paste0("analysis",as.integer(rnorm(1,100000,100)),as.integer(rnorm(1,100000,100)),as.integer(rnorm(1,100000,100)))

analysisdir = file.path("/apponefiles", randbase)
static.analysis.page(outdir = analysisdir, svg.files = plotfile, dfs = res.data2, show.xy =TRUE, overwrite = TRUE)

file.create(file.path(analysisdir, "ActualPage.html"),overwrite=TRUE)

sink(file.path(analysisdir, "ActualPage.html"))

foldchangefilename = paste0("foldchange",randbase)
metafoldfilename = paste0("metafold",randbase)

write.csv(out.data, file.path(analysisdir, foldchangefilename))
write.csv(metafold, file.path(analysisdir, metafoldfilename))

cat('
<!DOCTYPE html>
<!--
Copyright Genentech - A member of the Roche Group
@author Adrian Nowicki <adrian.nowicki@contractors.roche.com>
-->
<html>
    <head>
        <title>University of Arizona SRP-DMAC Olympus server</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <!-- THESE LINK & META TAGS ARE IMPORTANT FOR EMBEDDED DATASETS TO WORK -->
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link href="bundle-756ba12627.css" rel="stylesheet" type="text/css">
	<link rel="stylesheet" type="text/css" href="/AresC/semantic.min.css">
	<style>

	.ep-analysis-table td, .ep-analysis-table th{
	font-family: Lato,"Helvetica Neue",Arial,Helvetica,sans-serif;
	font-size: 95%;
	}

	.row-fluid .span5{
width: 100%;
margin-left:0%;
margin-top:10px;
}

.ep-analysis-plot {

}

.ep-analysis-plot .ep-plot-inner{
width: 100%;
}

.ep-analysis-plot .ep-side-menu{
}

.ep-analysis-table .ep-analysis-thead{
width:100%;
margin-top:10px;
}


	</style>
        <!-- [END] -->
    </head>
    <body>
	
<div class="App">
	<header class="App-header">
	<div class="ui inverted top fixed menu" style:"width:90%">
		<div class="ui container">
		<a class="header item" href="http://dmac.pharmacy.arizona.edu/Ares/Home">
		<h1 >Ares</h1>
		</a>
		<a class="item" href="http://dmac.pharmacy.arizona.edu">
		<h4 > Home</h4>
		</a>
		<a href="https://dmac.pharmacy.arizona.edu/Ares/redirect_uri?logout=https://dmac.pharmacy.arizona.edu" class="item">
		<h4>Logout</h4>
		</a>
		
			<div class="ui float right dropdown link item">
   		 		<span class="text">Menu</span>
    					<div class="menu">    
      						<a class="item" href="http://dmac.pharmacy.arizona.edu"> Home </a>
      						<a class="item" href="http://dmac.pharmacy.arizona.edu/Ares/Home"> Ares </a>
						<a class="item" href="https://dmac.pharmacy.arizona.edu/Ares/About/AresAbout.html"> About Ares </a>       							
						<a class="item" href="https://dmac.pharmacy.arizona.edu/Hermes/Home">  Hermes </a>  	       							
					</div>
			</div>
		</div>

	</div>
	</header>

<img class="ui centered medium image" src="/AresC/AresLogo.jpg" style = "padding-top: 100px;">

<div class="ui container appBody" style = "padding-top: 40px;">
	<div class="ui container" >
		<p class="p-t-15" style = "font-size: large;">
		Selected Files:</p>
	
	<div class="ui segment">	
			<div class="table-container" style="padding-top: 20px; max-height:340px;overflow-y: scroll;">
			<table class="ui very basic table">
				<thead class="">
				<tr class="">
				<th style="text-align: center;">
				Group 1</th>
				<th style="text-align: center;">
				Group 2</th>
				</tr>	
				</thead>
				<tbody>
				')
	temp1 = NULL
	temp2 = NULL


	for(i in 1:length(condition)){
	if(condition[i] == 'Treatment')
	{
	temp1=rbind(temp1,fn[i])
	}

		if(condition[i] == 'Control')
	{
		temp2=rbind(temp2,fn[i])

	}

	
	}
	if(length(temp1) >= length(temp2)){
		for(i in 1:length(temp1)){

			cat('<tr>
			<td style="text-align: center;">')
			cat(temp1[i])
			cat('</td>
			<td style="text-align: center;">')
		if(!is.null(temp2[i]) &  !is.na(temp2[i])){
			cat(temp2[i])
			cat('</td>
			</tr>')	
			}
		else{
			cat('</td>
			</tr>')	
		}
		}

	}

	if(length(temp1) < length(temp2)){

		for(i in 1:length(temp2)){
			cat('<tr>
			<td style="text-align: center;">')

		if(!is.null(temp1[i])&  !is.na(temp1[i])){
			cat(temp1[i])
			cat('</td>')	
			}
		else{
			cat('</td>')	
		}

			cat('<td style="text-align: center;">')
			cat(temp2[i])
			cat('</td>
			</tr>')
		}

	}

		
	
			cat('	</tbody>
				</table>
		 	</div>
	</div>
	</div>



</div>	
<div class="ui container" style = "padding-top: 30px;">

<div class="ui segment">

	<div style = "font-size: large;"> Save Data For Hermes Analysis </div>
	<br>
	
  	<input type="text" id="fname"  placeholder="File name..." maxlength="20" style = "height: 34px; border-radius: 5px;">
 	<button class="ui button" onclick="movefiles()">Save</button>

 <div id="Areserror" style = "font-size: large; display:none; padding-top: 20px;">
    <p>Enter a filename without special characters or spaces.<p>
  </div>

 <div id="Aressuccess" style = "font-size: large; display:none; padding-top: 20px;">
    <p id="successpar"><p>
  </div>


</div>
</div>

        <!--
            Containers are identified by the "ep-analysis-page-data-set" class.
            "container-fluid" class is also necessary for proper layout of descendants.

            You can control sources of the dataset and plot with custom
            attributes set on a container:
        -->
<div class="ui container" style = "padding-top: 30px;">

        <div id ="fig1" class="ep-analysis-page-data-set container-fluid"
             data-svg="')


f1svgfile <-  dir(path = file.path(analysisdir,"/data"),pattern="*.svg")

cat(paste0("data/",f1svgfile))


cat('"
             data-set="')


f1jsonfile <-  dir(path = file.path(analysisdir,"/data"),pattern="*.json")

cat(paste0("data/",f1jsonfile))

cat('"
             data-plot-zoomable="no"
             data-plot-height="800"
             data-table-rows="10"></div>

<br>
<br>

</div>


	
<script>
  function movefiles() {

var dirtyString = document.getElementById("fname").value;
var cleanString = dirtyString.replace(/[^a-z0-9]/gi, "");

if( dirtyString == cleanString ){

document.getElementById("Areserror").style.display = "none";

        $.ajax({
	  type: "POST",
          url: "/HermesResults/movefile.php",
          data: {"file" : "')
cat(paste0("/var/www/data/", username, "/Hermes/Data/"))
cat('" + document.getElementById("fname").value, "file2" : "') 
cat(file.path(analysisdir, foldchangefilename))
cat('","file3" : "')
cat(file.path(analysisdir, metafoldfilename))
cat('", "file4" : "')
cat(paste0("/var/www/data/", username, "/Hermes/Meta/"))
cat('" + document.getElementById("fname").value},
          success: function (response) {
             // do something
          },
          error: function () {
             // do something
          }
        });
document.getElementById("Aressuccess").style.display = "block";
document.getElementById("successpar").innerHTML = "File saved as " + cleanString;
 
}

else{
document.getElementById("Aressuccess").style.display = "none";
document.getElementById("Areserror").style.display = "block";

} 

  }
</script>

        <!-- THIS IS THE ONLY SCRIPT NEEDED, PUT IT ANYWHERE IN THE DOCUMENT -->
        <script src="config-937f59c213.js"></script>
        <script src="bundle-ee64cfcdb9.js"></script>
	<script type = "text/javascript" src="/AresC/jquery.min.js"></script>
	<script type = "text/javascript" src="/AresC/semantic.min.js"></script>
	<script type = "text/javascript"> 

$(".ui.dropdown")
  .dropdown()
;

</script>

    </body>
</html>
')

sink()
}

}

if(!is.null(analysisdir)){

if(dir.exists(analysisdir)){

cat('
<script>
window.open("')

cat(file.path("http://dmac.pharmacy.arizona.edu/apps", randbase, "ActualPage.html"))

cat('")

window.location.replace("http://dmac.pharmacy.arizona.edu/Ares/Home")


</script>
')

}

}

filenames2 = dir(path = "/apponefiles/")

if(length(filenames2) > 0){

for (i in 1:length(filenames2)){

if(difftime(Sys.time(), file.info(file.path("/apponefiles",filenames2[i]))$ctime, units="hours") > 24){


unlink(file.path("/apponefiles",filenames2[i]), recursive = TRUE)

}
}

}




	cat('</div>
	</div>


</div>')
} else
{

cat('

<p class="p-t-15" style = "font-size: large; ">
		There was a problem finding your account. Please contact us for assistance.  </p>

')

}
cat('
</div>

<script>
  function filterchange() 
{
document.getElementById("filter").value = document.getElementById("filter").value.replace(/\\\\/g, "");
}

</script>

<script type = "text/javascript" src="/AresC/jquery.min.js"></script>
<script type = "text/javascript" src="/AresC/semantic.min.js"></script>
<script type = "text/javascript"> 

$(".ui.dropdown")
  .dropdown()
;

</script>
</body>
</html>
')


