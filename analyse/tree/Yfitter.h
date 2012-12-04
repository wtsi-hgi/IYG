# include <fstream>
# include <sstream>
#include <iostream>
#include <string>
#include <sstream>
#include <algorithm>
#include <iterator>
# include "fitnode.h"
# include <map>
# include <string.h>

class Yfit {
  
  node<fitnode> tree; // the first node defining a tree
  //map<long int, vector<int> > seq_data;  // the mutation data
  map<string,map<long int, vector<int> > > seq_data; //the per-site mutation data
 
 public:

  void readTree(string treefile);
  void readGLF(string glffile, int mFlag);
  void fillTree();
  void fillTree(string sample);
  void fillTree(node<fitnode> *input_node,string sample);
  void calcOutput();
  void writeOutput();
  node<fitnode> *getTree();
  vector<string> getSamples();

};

/****************************/
/*** setters and getters  ***/
/****************************/ 

node<fitnode> *Yfit::getTree(){
  return(&tree);
}

vector<string> Yfit::getSamples(){

  vector<string> samples;
  for(map<string,map<long int, vector<int> > >::iterator i = seq_data.begin(); i != seq_data.end(); ++i) {
    samples.push_back(i->first);
  }
  
  return(samples);

}


/********************/
/***   readTree   ***/
/********************/   

/* populates the branches and mutations of node<fitnode> tree object with data contained in a phyloXML file treefile */

void Yfit::readTree(string treefile){

  /* open input stream */
  ifstream input;
  input.open(treefile.c_str());
  
  /* define iterators */
  string::iterator position, mutposition;

  /* define temporary storages */
  string command, parameter, line;
  string mutname, chrom, location_string, ancestor, derived;
  long int location;

  /* define flags */
  int started = 0;
  int reading = 0;
  int countdown = 3;

  /* define pointers to trees */
  node<fitnode> *current_node;
  node<fitnode> *temp_pointer;
  current_node = &(tree);

  //  cout << "3! ";


  /* read all files*/
  while (!input.eof()){
    
     getline(input,line);
    
     /* read each character */
     for(position = line.begin(); position != line.end(); position++){
      
       /* if < is present, start reading commands*/
       if (*position == '<'){
 	started = 1;
       }
      
       /* if in a command, start recording it */
       if (started == 1){
 	command.push_back(*position);
       }

       /* if in a parameter, start reading it*/
       if (reading == 1){
 	parameter.push_back(*position);
       }
      
       /* if the command has ended, process it */
       if (*position == '>'){

	 /* countdown section - must meet three criteria to begin reading */
	
	 /* 1) we need to see the phyloxml tag*/
	 if (command.substr(0,9) == "<phyloxml"){
	   countdown = 2;
 	  //cout << "2! ";
	   
	   /* 2) we need to see the phylogeny tag */
	 } else if (countdown == 2 && command.substr(0,10) == "<phylogeny"){
	   countdown = 1;
	   //cout << "1! ";
	   
	   /* 3) we need to see the first clade */
	 } else if (countdown == 1 && command == "<clade>"){
	   
	   countdown = 0;
	   //cout << "Blast off!" << endl;
	   

	   /* if all conditions are met, we process commads */
	 } else if (countdown == 0){
	   
	   if (command == "<clade>"){
	     // create a new daughter and change current_node pointer to it
	     // 	    cout << "open clade" << endl;
	     
	     temp_pointer = current_node->createDaughter();
	     current_node = temp_pointer;
	     
	   }
	   
	   if (command == "</clade>"){
	     // change current_node pointer to the parent
	     // 	    cout << "close clade" << endl;
	     
	     temp_pointer = current_node->getParent();
	     current_node = temp_pointer;
	   }
	   
	   if (command == "<name>"){
	     // start reading the node name
	     reading = 1;
	     //cout << "start reading name" << endl;
	   }
	  
	   if (command == "</name>"){
	     // stop reading the node name and save it
	     reading = 0;
	     parameter.erase(parameter.end()-7,parameter.end());
	     //cout << "stop reading name:" << parameter << endl;
	     
	     current_node->node_info.setName(parameter);
	     
	     parameter.clear();
	   }
	   
	   if (command.substr(0,52) == "<property datatype=\"xsd:string\" ref=\"point_mutation:"){
	     // begin reading mutation data, and extract mutation name
	     reading = 1;
	     
	     for (mutposition = command.begin()+52; mutposition != command.end(); mutposition++){
	       if (*mutposition == '\"'){
		 break;
	       }
	       mutname.push_back(*mutposition);
	     }
	     
	     //cout << "start reading mutation data:" << mutname << endl;
	   }
	   
	   if (command == "</property>"){
	     // stop reading mutation data and write it to the current node
	     
	     reading = 0;
	     parameter.erase(parameter.end()-11,parameter.end());
	     
	     mutposition = parameter.begin();
	     
	     /* read chromosome */
	     while (mutposition != parameter.end()){
	       if (*mutposition == ':'){
		 mutposition++;
		 break;
 	      }
	       chrom.push_back(*mutposition);
 	      mutposition++;
	     }
	    
	     /* read co-ordinates */
	     while (mutposition != parameter.end()){
	       if (*mutposition == ','){
		 mutposition++;
		 break;
	       }
	       location_string.push_back(*mutposition);
	       mutposition++;
	     }	        
	     
	     /* read ancestor state */
	     while (mutposition != parameter.end()){
	       if (*mutposition == ','){
		 mutposition++;
		 break;
	       }
	       ancestor.push_back(*mutposition);
	       mutposition++;
	     }
	     
	     /* read derived state */
	     while (mutposition != parameter.end()){
	       derived.push_back(*mutposition);
 	      mutposition++;
	     }
	     
	     /* convert location to long int */
	     istringstream buffer(location_string);
	     buffer >> location;
	     
	     /* write it all */
	     current_node->node_info.addMutation(mutname,chrom,location,ancestor,derived);
	     
	     //cout << "stop reading mutation data:" << mutname << "=" << chrom << "-" << location << ":" << ancestor << "/" << derived << endl;
	     
	     /* clear temp objects */
	     parameter.clear();
	     chrom.clear();
	     location_string.clear();
	     ancestor.clear();
	     derived.clear();
	     mutname.clear();
	     
	   }
	   
	 }
	 
	 //cout << command << endl;
	 
	 /* clear the command and stop reading */
	 command.clear();
	 started = 0;
       }
       
     }
   }

}


/******************/
/*** readGLF    ***/
/******************/

void Yfit::readGLF(string glffile, int mFlag){
  
  /* this function fills up the map seq_data for text-dump of a GLF file of likelihoods*/

  string entry;
  string::iterator position;
  int field;
  vector<int> likelihoods;
  string sample = "sample";

  long int location;
  int base_likelihood, likelihood;

  /* open the glf file */
  ifstream glf_file;
  string glf_line;
  glf_file.open(glffile.c_str());

  /* read in each line */
  while (!glf_file.eof()){

    getline(glf_file,glf_line);
      
    /* skip blank lines */
    if(glf_line == ""){
      continue;
    }

    istringstream iss(glf_line);
    vector<string> tokens;
    copy(istream_iterator<string>(iss), istream_iterator<string>(),back_inserter<vector<string> >(tokens));

    if (mFlag && tokens.size() < 17){
      cerr << "Error: No sample ID in file at position " << tokens[1] << endl;
      exit(-1);
    }

    if (mFlag){
      sample = tokens[16];
    }


    istringstream buffer(tokens[1]);
    buffer >> location;
    istringstream buffer2(tokens[3]);
    buffer2 >> base_likelihood;
    
    likelihoods.clear();
    
    for (int k=0; k < 10; k++){
      
      istringstream buffer3(tokens[k + 6]);
      buffer3 >> likelihood;
      likelihoods.push_back(likelihood+base_likelihood);
    }    
    

    seq_data[sample][location] = likelihoods;
    
  }
 
}


/******************/
/*** fillTree   ***/
/******************/

void Yfit::fillTree(){
  fillTree(&tree,"sample");
}



void Yfit::fillTree(string sample){
  fillTree(&tree,sample);
}

void Yfit::fillTree(node<fitnode> *input_node, string sample){

  map<long int, vector<int> >::iterator mutation;

  map<string, int> bases;
  bases["A"] = 0;
  bases["C"] = 4;
  bases["G"] = 7;
  bases["T"] = 9;

  double M = 0;
  double notM = 0;

  if (input_node->node_info.getNmutations() == 0){
    M = 0;
    notM = 0;
  }

  for (int i=0; i < input_node->node_info.getNmutations(); i++){
    /* calc M and notM for all mutations */  
    mutation = seq_data[sample].find(input_node->node_info.getMutation(i).location);

    /* if there is no data */
    if (mutation == seq_data[sample].end()){
      //M = 1;
      //notM = 1;
    } else {

      //     cout << bases[input_node->node_info.getMutation(i).ancestor] << ".";
      //cout << mutation->second[bases[input_node->node_info.getMutation(i).ancestor]] << ".";

      M += mutation->second[bases[input_node->node_info.getMutation(i).derived]];
      notM += mutation->second[bases[input_node->node_info.getMutation(i).ancestor]];
    }
  }

  //cout << input_node->node_info.getName() << ": M= " << M << " notM= " << notM << endl;

  input_node->node_info.setM(M);
  input_node->node_info.setNotM(notM);

  /* call this function on all daughter nodes, if any */

  for (int j = 0; j < input_node->getNdaughters(); j++){
    fillTree(input_node->getDaughter(j),sample);
  }

}

/*******************/
/*** calcOutput  ***/
/*******************/

void Yfit::calcOutput(){
 
  /* this function calculates the likelihood for all nodes */

  tree.node_info.calcNotL();
  tree.node_info.calcPartialL();
  tree.node_info.calcL();

}

/********************/
/*** writeOutput  ***/
/********************/

void Yfit::writeOutput(){

  /* this function writes the tree to a phyloXML file, with L values as support values*/

}
