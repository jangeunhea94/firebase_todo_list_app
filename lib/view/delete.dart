import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_todo_list_app/model/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Delete extends StatefulWidget {
  const Delete({super.key});

  @override
  State<Delete> createState() => _DeleteState();
}

class _DeleteState extends State<Delete> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Lists'),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
                .collection('deletelist')
                .orderBy('date', descending: false)
                .snapshots(),
        builder: (context, snapshot) {
          if(snapshot.hasError){
            return Center(
              child: Text('삭제 목록을 불러오지 못했습니다. .'),
            );
          }
          if (!snapshot.hasData){
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final documents = snapshot.data!.docs;

          if (documents.isEmpty){
            return Center(
              child: Text('삭제 한 목록이 없습니다.'),
            );
          }
          return ListView(
            children: documents
                      .map((e) => buildItemWidget(e))
                      .toList(),
          );
        },
        )
    );
  }//build

  // ------ function -----
  Widget buildItemWidget(DocumentSnapshot doc) {
    if (doc['date'] == null) {
      return SizedBox.shrink();
    }
    final todo = Todo(
      content: doc['content'], 
      date: doc['date']
      );
      final date = todo.date.toDate();
      final dateText = 
      '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

      return Slidable(
        key: ValueKey(doc.id),
        startActionPane: ActionPane(
          motion: BehindMotion(), 
          children: [
            SlidableAction(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.restore,
              label: '복원',
              onPressed: (context) => restoreAction(doc.id, todo),
            )
          ]
       ),
        child: Card(
          margin: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.calendar_today),
                SizedBox(width: 12,),
                Expanded(
                  child: Text('${todo.content} / $dateText ') 
              )
            ],
          ),
        ),
            ),
      );
  }

  Future<void> restoreAction(String docId, Todo todo) async {
    final db = FirebaseFirestore.instance;
  final batch = db.batch();

  // 원래 문서 ID와 내용, 날짜로 복원
  batch.set(
    db.collection('todolist').doc(docId),
    {
      'content': todo.content,
      'date':todo.date,
       }
    );
    // 삭제 목록에서는 제거
    batch.delete(
      db.collection('deletelist').doc(docId),
    );
    await batch.commit();
  }
}//class