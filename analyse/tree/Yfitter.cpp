# include "Yfitter.h"
# include <string.h>
#include <set>

using namespace std;

node<fitnode> *tempy;

double diff = 8.685; // the change in log-likelihood corresponding to a deltaAIC difference of 4
//double diff = 150;

node<fitnode> *getBestDaughter(node<fitnode> *node, double diff){

  int L;
  int minL = 1000000;
  int tie = 0;

  cout << node->node_info.getName();
  //cout << node->node_info.getName() << ":" << node->node_info.getL() << " (" << node->getNdaughters() << ")" << endl;

  if (node->getNdaughters() < 2){
    return(node);
  } else {
    
    for (int i = 0; i < node->getNdaughters(); i++){
      
      L = node->getDaughter(i)->node_info.getL();
      //cout << i << ":" << node->getDaughter(i)->node_info.getName() << "=" << L << " (" << minL << ")" << endl;
      if ((L >= minL) & (L <= minL + diff)){
	tie = 1;
      }
      if (L < minL){
	tempy = node->getDaughter(i);
	minL = L;
	tie=0;
      }
    }
    
  }

  //cout << "Result: " << tempy->node_info.getName() << "=" << tempy->node_info.getL() << endl;
  if (tie == 1){
    return(node);
  }
  return(getBestDaughter(tempy,diff));
      
}


void getNodeInfo(node<fitnode> *node,int base_likelihood,int moreinfo){

  if (moreinfo) {cout << node->node_info.getName() << ":" << node->node_info.getL() - base_likelihood << endl;}
  else if (node->node_info.getL() == base_likelihood){
    cout << node->node_info.getName() << "\t";
    getBestDaughter(node,0);
    cout << "\t";
    getBestDaughter(node,diff);
  }
}

int printHapInfo(node<fitnode> *current_node, int moreinfo){

  node<fitnode> *temp_pointer;
  int base_likelihood;

 /* base */
  if (moreinfo) {cout << current_node->node_info.getName() << ":" << current_node->node_info.getL() << endl;}
  base_likelihood = current_node->node_info.getL();

  /*A*/
  temp_pointer = current_node->getDaughter(0);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);
  //cout << temp_pointer->node_info.getName() << ":" << temp_pointer->node_info.getPartialL() << endl;
  //cout << temp_pointer->node_info.getName() << ":" << temp_pointer->node_info.getNotM() << endl;
  //cout << temp_pointer->node_info.getName() << ":" << temp_pointer->node_info.getNotL() << endl;

  /* B */
  current_node = temp_pointer->getParent()->getDaughter(1)->getDaughter(0);
  getNodeInfo(current_node,base_likelihood,moreinfo);
  
  /* C-cludge1 */
  if (moreinfo) {cout << "C:" << current_node->getParent()->getDaughter(1)->getDaughter(1)->getDaughter(0)->node_info.getL() - base_likelihood << endl;}
  else if (current_node->getParent()->getDaughter(1)->getDaughter(1)->getDaughter(0)->node_info.getL() == base_likelihood){
    cout << "C\t";
    getBestDaughter(current_node->getParent()->getDaughter(1)->getDaughter(1)->getDaughter(0),0);
    cout << "\t";
    getBestDaughter(current_node->getParent()->getDaughter(1)->getDaughter(1)->getDaughter(0),diff);
  }

  /* DE* */
  temp_pointer = current_node->getParent()->getDaughter(1)->getDaughter(0)->getDaughter(0);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);
  
  /* D */
  current_node = temp_pointer->getParent()->getDaughter(1);
  getNodeInfo(current_node,base_likelihood,moreinfo);
  
  /* E */
  temp_pointer = current_node->getParent()->getDaughter(2);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

  /* C-cludge2 */
  current_node = temp_pointer->getParent()->getParent()->getDaughter(1)->getDaughter(0);
  //cout << current_node->node_info.getName() << ":" << current_node->node_info.getL() - base_likelihood << endl;

  /* F(false) */
  temp_pointer = current_node->getParent()->getDaughter(1)->getDaughter(0);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

  /* G */
  current_node = temp_pointer->getParent()->getDaughter(1);
  getNodeInfo(current_node,base_likelihood,moreinfo);

  /* H */
  temp_pointer = current_node->getParent()->getDaughter(2);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

  /* I */
  current_node = temp_pointer->getParent()->getDaughter(3)->getDaughter(0);
  if (moreinfo) { cout << "I" << ":" << current_node->node_info.getL() - base_likelihood << endl;}
  else if (current_node->node_info.getL() == base_likelihood){
    cout << "I" << "\t";
    getBestDaughter(current_node,0);
    cout << "\t";
    getBestDaughter(current_node,diff);
  }

  //cout << "I" << ":" << current_node->node_info.getPartialL() << endl;

  /* J */
  temp_pointer = current_node->getParent()->getDaughter(1);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

  /* K(false) */
  current_node = temp_pointer->getParent()->getParent()->getDaughter(4)->getDaughter(0);
  getNodeInfo(current_node,base_likelihood,moreinfo);

  /* L */
  temp_pointer = current_node->getParent()->getDaughter(1);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

  /* M */
  current_node = temp_pointer->getParent()->getDaughter(2);
   getNodeInfo(current_node,base_likelihood,moreinfo);

  /* NO* */
  temp_pointer = current_node->getParent()->getDaughter(3)->getDaughter(0);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

  /* N */
  current_node = temp_pointer->getParent()->getDaughter(1);
  getNodeInfo(current_node,base_likelihood,moreinfo);

  /* O */
  temp_pointer = current_node->getParent()->getDaughter(2);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

  /* P* */
  current_node = temp_pointer->getParent()->getParent()->getDaughter(4)->getDaughter(0);
  getNodeInfo(current_node,base_likelihood,moreinfo);

  /* Q */
  temp_pointer = current_node->getParent()->getDaughter(1);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

  /* R */
  current_node = temp_pointer->getParent()->getDaughter(2);
  getNodeInfo(current_node,base_likelihood,moreinfo);

  /* S */
  temp_pointer = current_node->getParent()->getParent()->getDaughter(5);
  getNodeInfo(temp_pointer,base_likelihood,moreinfo);

 
  /* T */
  current_node = temp_pointer->getParent()->getDaughter(6);
  getNodeInfo(current_node,base_likelihood,moreinfo);

  cout << endl;

  return(0);

}


int main(int argc, char* argv[]){

   /* check for specific mutations */

  node<fitnode> * current_node;

  node<fitnode> * temp_pointer;
  int base_likelihood;
  int multifile = 0;
  int moreinfo = 0;
  Yfit fit;
  vector<string> samples;
  
  argv++;
  argc--;
  while(1){
    if (argc == 0) {  cerr << "Usage: Yfitter [-m -s] [-q Q] tree.xml glffile.txt" << endl; exit(-1); }
    else if (!strcmp(*argv,"-h")) {cerr << "Usage: Yfitter  [-m -s] tree.xml glffile.txt" << endl; exit(-1);}
    else if (!strcmp(*argv,"-m")) { multifile=1; argv++; argc--;}
    else if (!strcmp(*argv,"-s")) { moreinfo = 1; argv++; argc--;}
    else if (!strcmp(*argv,"-q")) {argv++; argc--; diff=atof(*argv); argv++; argc--;}
    else {
      if (argc != 2 || !strcmp(*argv,"-h")) { cerr << "Usage: Yfitter [-m -s] [-q Q] tree.xml glffile.txt" << endl; exit(-1); } 
else {break;}
    }
  }    
  
  fit.readTree(argv[0]);

  if (!multifile){

    fit.readGLF(argv[1],0);
    fit.fillTree();
    fit.calcOutput();
    
    printHapInfo(fit.getTree(),moreinfo);
  } else {

    fit.readGLF(argv[1],1);
    samples = fit.getSamples();

    for (int i=0; i < samples.size(); i++){
      fit.fillTree(samples[i]);
      fit.calcOutput();
      cout << samples[i];
      if (moreinfo){
	cout << ":\n";
      } else {
	cout << "\t";
      }

      printHapInfo(fit.getTree(),moreinfo);
 
    }
  }
  
  return(0);

}
