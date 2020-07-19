dirS = getDirectory("Choose source Directory"); 
dirD = getDirectory("Choose destination Directory");

pattern = ".*"; // regex for selecting all the files in the folder

filenames = getFileList(dirS);
count = 0;
for (i = 0; i < filenames.length; i++) {
	currFile = dirS+filenames[i];
	if(matches(filenames[i], pattern)) { // process tif files matching regex
		//run("Bio-Formats Importer", "open=["+currFile+"] view=[Hyperstack] stack_order=XYCZT autoscale");
		run("Bio-Formats Importer", "open=["+currFile+"] autoscale color_mode=Default concatenate_series open_all_series view=Hyperstack stack_order=XYCZT");
		count++;
		run("HyperStackReg ", "transformation=Translation channel1 show");
		saveAs("Tiff", dirD+getTitle());
		close(); // close registered file
		close(); // close original file
	}
}
print("Number of files processed: "+count);