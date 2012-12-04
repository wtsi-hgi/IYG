/************************************************************************/
/*** node.h - C++ code for making tree objects                        ***/
/************************************************************************/
/***                                                                  ***/
/*** This file contains the class "node", and a few subclasses.       ***/
/*** nodes are defined using "node<node_type> node_name", where       ***/
/*** node_type is a subclass that holds the node's use-specific data  ***/
/***                                                                  ***/
/*** Nodes have a number of elementary functions associated with them ***/
/*** (those associated with moving through trees) but more advanced   ***/
/*** functions should be called via the "tree" class (see tree.h)     ***/
/***                                                                  ***/
/*** Two subclasses are included here, bnode, in which nodes have a   ***/
/*** name but no other information, and lnode, in which nodes have a  ***/
/*** branch length associated with them.                              ***/
/***                                                                  ***/
/*** Luke <lj4@sanger.ac.uk>, 9/01/08                                 ***/
/***                                                                  ***/
/************************************************************************/

#include <vector>
#include <iostream>

using namespace std;


/*********************************/
/*** class definition          ***/
/*********************************/

/* the basic node class consists of a vector of pointers to a set of daughter nodes */
/* plus a node_info object of template class node_type */

template<typename node_type>
class node {

  /* private objects */

  int Ndaughters; // assume no daughters unless we say otherwise
  vector<node *> daughters; // vector of pointers to daughters
  node *parent; // pointer to parent
  int orphon; // set to 1 if the node has no parent
  int nodeID; // identifies which daughter the node is relative to parent node

 public: 
  node_type node_info; // type-specific information (e.g. branch length)
  /* public functions */

  /*constructor and destructor */
  node(int guessNdaughters);
  ~node();

  /* daughter operations - note, you cannot remove individual daughters (do we want to?) */
  node *createDaughter();
  void createDaughters(int NnewDaughters, vector<node *> *pointers);
  void clearDaughters();
 
  /* setters */
  void setParent(node *newParent, int newNodeID);
  void setNodeID(int newID);

  /* getters */
  node *getDaughter(int i);
  node *getParent();
  string getName();
  int getNdaughters();
  int getNodeID();
  int getOrphon();
};




/******************************************/
/*** constructor and destructor         ***/
/******************************************/


/* this function takes a guess of how many daughter they'll be, and allocated that much vector space*/
/* if no guess is made, or the node is guessed to be a leaf (no daughters), nothing happens */
template <typename node_type> node<node_type>::node(int guessNdaughters = 0){
  if (guessNdaughters != 0){
    daughters.reserve(guessNdaughters);
  }
  
  Ndaughters = 0; // no daughters at start-up
  orphon = 1; // no parent yet

  node_info.hostnode = this; // set a pointer back to the host node from the info object

}

/* destroy node and all subnodes */
template <typename node_type> node<node_type>::~node(){
  
    for (int i=0; i < Ndaughters; i++){
    daughters.back()->~node();
    daughters.pop_back();
  }

}


/*******************************/
/*** daughter operations     ***/
/*******************************/


/* creates a single daughter, returns a pointer to it */
template <typename node_type> node<node_type> * node<node_type>::createDaughter(){

  node<node_type> *newDaughter = new node<node_type> [1]; 

  daughters.push_back(newDaughter);
  daughters.back()->setParent(this,Ndaughters);
  Ndaughters++;

  return(newDaughter);
}

/* adds a vector of new daughters to the current vector of daughters */ 
template <typename node_type> void node<node_type>::createDaughters(int NnewDaughters, vector<node *> *pointers){
  for (int i=0; i < NnewDaughters; i++){
    (*pointers)[i] = createDaughter();
  }
}
  
/* clears all the current daughters*/
template <typename node_type> void node<node_type>::clearDaughters(){
  daughters.clear();
}

/******************************/
/*** setters and getters    ***/
/******************************/

/* setters */

template <typename node_type> void node<node_type>::setParent(node *newParent,int newNodeID){
  parent = newParent;
  nodeID = newNodeID;
  orphon = 0;
}

template <typename node_type> void node<node_type>::setNodeID(int newNodeID){
  nodeID = newNodeID;
}

  /* getters */
template <typename node_type> node<node_type> * node<node_type>::getDaughter(int i){
  return(daughters[i]);
}

template <typename node_type> node<node_type> *node<node_type>::getParent(){
  if (orphon == 1){
    return(NULL);
  } else {
  return(parent);
  }
}

template <typename node_type> int node<node_type>::getNdaughters(){
  return(Ndaughters);
}

template <typename node_type> int node<node_type>::getNodeID(){
  return(nodeID);
}

template <typename node_type> int node<node_type>::getOrphon(){
  return(orphon);
}



/*****************************/
/*** node_type: bnode      ***/
/*****************************/

/* the basic node: it has a name, and a pointer back to it's host node, but nothing else */

/* class definition */
class bnode{
 protected:
  string nodename; // do we want this to be a unique number instead? 
 public:
  node<bnode> *hostnode; // pointer back to host node

  void setName(string newNodename);
  string getName();
};

/* getter and setter */

void bnode::setName(string newNodename){
  nodename = newNodename;
}

string bnode::getName(){
  return(nodename);
}


/*****************************/
/*** node_type: lnode      ***/
/*****************************/

/* lnodes have branch lengths between node and parent. Inherits from bnode */


/* class definition */
class lnode: public bnode{

 protected:

double branchlength; // the branch length between node and it's parent

public:

  node<lnode> *hostnode;

  /* new setters and getters */
  void setBranchlength(double newBranchlength);
  double getBranchlength();

};

/* getter and setter */


void lnode::setBranchlength(double newBranchlength){
  branchlength = newBranchlength;
}

double lnode::getBranchlength(){
  return(branchlength);
}





/*************************/
/*** Testing           ***/
/*************************/ 

/* this function tests various aspects of the object are functioning */

int test(){
  
  cout << "\nStarting test \n\n" ;

  /* create a node (with branch lengths) */
  node<lnode> root;
  
  /* name it */
  string rootname = "root node";
  root.node_info.setName(rootname);
  cout << "This node is called " << root.node_info.getName() << ". ";

  /* give it a branch length */
  root.node_info.setBranchlength(10);
  cout <<"If has a branch length of " << root.node_info.getBranchlength() << ". ";

  /* check it is an orphan */
  if (root.getParent() == NULL){
    cout << "This node has no parent! ";
  } else {
    cout << "This node's parent is " << root.getParent()->node_info.getName() << ". ";
  }

  /* create a set of daughter nodes */
  vector<node<lnode> *> daughters;
  daughters.reserve(5);

  root.createDaughters(5,&daughters);
 
  /* name them */
  string genetic = "genetic";
  string daughtername = "daughter node";

  for (int i = 0; i < 5; i++){
    daughters[i]->node_info.setName(genetic);
  }
  daughters[0]->node_info.setName(daughtername);

  cout << root.node_info.getName() << " has " << root.getNdaughters() << " daughters, called ";
  
   for (int j = 0; j < root.getNdaughters(); j++){
     cout << root.getDaughter(j)->node_info.getName() << " (nodeID = " << root.getDaughter(j)->getNodeID() << " == " << j <<"), ";
   }
  

   /* check that nodes trace back to their parents */

   cout << "\n\nThis nodes name is " << daughters[1]->node_info.getName() << ". ";

   if (daughters[1]->getParent() == NULL){
     cout << "This node has no parent! ";
   } else {
     cout << "This node's parent is " << daughters[1]->getParent()->node_info.getName() << ". ";
   }
  

   cout << "\n\nTest Complete \n\n";
   /* should all be working */
 
  return(0);
}
