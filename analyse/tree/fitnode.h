#include "node.h"
#include <cmath>

/*****************************/
/*** node_type: fitnode   ***/
/*****************************/

/* Contains information required for fitting individuals to a tree, as well as functions to */ 
/* calculate the likelihood of the individual belonging to the node's branch. Inherits from bnode. */

/* basic structure - mutation (should this be a struct?) */
class mutation{
 public:
 
  string name;
  string chrom;
  long int location;
  string ancestor;
  string derived;

};



/* class definition */
class fitnode: public bnode{
 protected:

  double M; // the negative log likelihood of seeing the data given that the branch mutations occured 
  double notM; // the negative log likelihood of seeing the data given that the branch mutations did not occur

  double notL; // the negative log likehood of the not seeing any of the mutations downstream of this node
  double partialL; // the negative log likehood of sample belonging to this branch given all upsteam mutations
  double L; // the negative log likehood of sample belonging to this branch given all data
  
  vector<mutation> mutations;
  int Nmutations;

public:

  node<fitnode> *hostnode; // pointer back to the host node

  fitnode();

  /* setters and getters */
  void setM(double newM);
  double getM();

  void setNotM(double newNotM);
  double getNotM();
 
  void setnotL(double newNotL);
  double getNotL();
  
  void setPartialL(double newPartialL);
  double getPartialL();
 
  void setL(double newL);
  double getL();

  void addMutation(string name,string chrom, long int location, string ancestor, string derived);
  void clearMutations();
  mutation getMutation(int i);

  int getNmutations();

  /* calculating functions */

  void calcNotL();
  void calcPartialL();
  void calcL();

};

fitnode::fitnode(){
  Nmutations = 0;
}

/* setters and getters */
void fitnode::setM(double newM){
  M = newM;
}   

double fitnode::getM(){
  return(M);
}

void fitnode::setNotM(double newNotM){
  notM = newNotM;
}

double fitnode::getNotM(){
  return(notM);
}

void fitnode::setnotL(double newNotL){
  notL = newNotL;
}

double fitnode::getNotL(){
  return(notL);
}

void fitnode::setPartialL(double newPartialL){
  partialL = newPartialL;
}

double fitnode::getPartialL(){
  return(partialL);
}

void fitnode::setL(double newL){
  L = newL;
}

double fitnode::getL(){
  return(L);
}

void fitnode::addMutation(string newName, string newChrom, long int newLocation, string newAncestor, string newDerived){
  mutation temp;
  
  temp.name = newName;
  temp.chrom = newChrom;
  temp.location = newLocation;
  temp.ancestor = newAncestor;
  temp.derived = newDerived;

  mutations.push_back(temp);

  Nmutations++;
}

void fitnode::clearMutations(){
  mutations.clear();
  Nmutations = 0;
}

mutation fitnode::getMutation(int i){
  return(mutations[i]);
}

int fitnode::getNmutations(){
  return(Nmutations);
}

/* calculating functions */

/* gets this node and all descedents to calculate their notL value */
void fitnode::calcNotL(){
  
  notL = notM;

  for (int i = 0; i < hostnode->getNdaughters(); i++){
    hostnode->getDaughter(i)->node_info.calcNotL();
    notL += hostnode->getDaughter(i)->node_info.getNotL();
  }
}

/* calculates the partialL for this node and all it's descendants */ 

void fitnode::calcPartialL(){

  /* the partialL is equal to the likelihood of branch mutations... */
  partialL = M;

  /* ...times by the parent's partialL, if any... */
  if (hostnode->getOrphon() == 0){
    
    partialL += hostnode->getParent()->node_info.getPartialL();

    /*...times by  sum of notLs of all sibling branches, if any */
    for (int i = 0; i < hostnode->getParent()->getNdaughters(); i++){

      if (i != hostnode->getNodeID()){
	partialL += hostnode->getParent()->getDaughter(i)->node_info.getNotL();
      }
      
    }
  }

 /* and get the daughters to do it */ 
 for (int j = 0; j < hostnode->getNdaughters(); j++){
   hostnode->getDaughter(j)->node_info.calcPartialL();
 }

}

void fitnode::calcL(){
  
  double daughterL;
  double temp;


  /* initialise L */
  if (hostnode->getNdaughters() == 0){
    L = partialL;
  } else {
    L = 100000;
  }

  /* */

  // cout << " : ";

  for (int i = 0; i < hostnode->getNdaughters(); i++){
    hostnode->getDaughter(i)->node_info.calcL();
    daughterL = hostnode->getDaughter(i)->node_info.getL();
    
    //cout << daughterL << "/" << L <<"/";
    //temp = pow(2,daughterL-L);
    L = min(L,daughterL);//daughterL - log2(temp + 1);
    //cout << temp << "/" << L << " ";
  }
}

