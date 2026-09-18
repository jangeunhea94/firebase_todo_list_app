import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_todo_list_app/model/todo.dart';
import 'package:firebase_todo_list_app/view/delete.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController contentController = TextEditingController();
  
  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo Lists'),
        centerTitle: true,
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.to(Delete()),
                icon: Icon(Icons.delete_forever)
                ),
              IconButton(
                onPressed: () => showAddDialog(),
                icon: Icon(Icons.add_outlined)
                )
            ],
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
                .collection("todolist")
                .orderBy('date', descending:false)
                .snapshots(), 
        builder: (context, snapshot) {
          if(!snapshot.hasData){
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final documents = snapshot.data!.docs;
          return ListView(
            children: documents.map((e) => buildItemWidget(e)).toList(),
          );
        },
       ),
    );
  } // build

  // ----- function -----
  Widget buildItemWidget(DocumentSnapshot doc) {
    if (doc['date'] == null) {
      return const SizedBox.shrink();
      }
    final todolist = Todo(
      content: doc['content'], 
      date: doc['date']
      );

      // Timestamp를 날짜로 변환하고 날짜 부분만 표시
      final date = todolist.date.toDate();
      final dateText = 
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      return Slidable(
        key: ValueKey(doc.id),
        endActionPane: ActionPane(
          motion: BehindMotion(), 
          children: [
            SlidableAction(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_forever,
              label: '삭제',
              onPressed: (context) => deleteAction(doc.id, todolist),
            ),
          ]
        ),
        child: GestureDetector(
          onTap: () {
            showupdateDialog(doc.id, todolist.content);
          },
          child: Card(
            margin: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('${todolist.content} / $dateText'),
                  )
                ],
              ),
              ),
          ),
        ),
      );
  }
   
   void showAddDialog() {
    contentController.clear();
    Get.defaultDialog(
      title: 'Todo List',
      content: TextField(
        controller: contentController,
        decoration: InputDecoration(
          labelText: '추가할 내용',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => insertAction(), 
          child: Text('추가하기')
        )
      ]
    );
   }
  // Firebase에 할 일 저장
  Future<void> insertAction() async {
    String content = contentController.text.trim();
    if (content.isEmpty) return;

    await FirebaseFirestore.instance.collection('todolist').add({
      'content':content,
      'date': FieldValue.serverTimestamp(),
    });
    Get.back();
  } 

  void showupdateDialog(String docId, String contnet){
    contentController.text = contnet;

    Get.defaultDialog(
      title: 'Todo List 수정',
      content: TextField(
        controller: contentController,
        decoration: InputDecoration(
          labelText: '수정할 내용',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => updateAction(docId), 
          child: Text('수정하기')
        )
      ]
    );
  }

  Future<void> updateAction(String docId) async {
    String content = contentController.text.trim();
    if (content.isEmpty)return;

    await FirebaseFirestore.instance
          .collection('todolist')
          .doc(docId)
          .update({'content':content});

    Get.back();
  }

  Future<void> deleteAction(String docId, Todo todo) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    //같은 문서 ID로 삭제 목록에 저장
    batch.set(
      db.collection('deletelist').doc(docId),
      {
        'content': todo.content,
        'date': todo.date,
      }
    );

    // 원래 목록에서 삭제
    batch.delete(
      db.collection('todolist').doc(docId)
    );
    await batch.commit();
  }
} // class