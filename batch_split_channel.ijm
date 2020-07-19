dirS = getDirectory("_Choose source Directory");
dirD = getDirectory("_Choose destination Directory");

pattern = ".*"; // for selecting all the files in the folder

// different examples of regex-based selection 
//pattern = "01-03.*Pos [3-9].*";
//pattern = ".*Pos [7-9].*";
//pattern = "01-02.*";

filenames = getFileList(dirS);
count = 0;
for (i = 0; i < filenames.length; i++) {
	currFile = dirS+filenames[i];
	if(matches(filenames[i], pattern)) { // process tif files matching regex
		run("Bio-Formats Importer", "open=["+currFile+"] view=[Hyperstack] stack_order=XYCZT autoscale");
		count++;
// selecting all channels		
//		run("HyperStackReg ", "transformation=Affine show");
// Use the following for selecting specific channels
		run("Split Channels");
		saveAs("Tiff", dirD+getTitle());
		close(); // close C3
		saveAs("Tiff", dirD+getTitle());
		close(); // close C2
		saveAs("Tiff", dirD+getTitle());
		close(); // close C1
	}
}
print("Number of files processed: "+count);