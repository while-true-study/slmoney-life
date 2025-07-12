import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../providers/TransactionProvider.dart';
import '../models/transaction.dart';
import 'AddTransactionScreen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // MainActivity 채널 이름 맞추기
  static const _eventChannel =
  EventChannel('com.example.moneymanager/notifications');
  late StreamSubscription _eventSub;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후에 EventChannel 구독 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eventSub = _eventChannel.receiveBroadcastStream().listen(
            (event) {
          debugPrint('Received EventChannel data: $event');
          final data = json.decode(event as String) as Map<String, dynamic>;
          // Provider에 전달해 Hive에 저장 & UI 갱신
          Provider.of<TransactionProvider>(context, listen: false)
              .handleNotification(data);
        },
        onError: (err) {
          debugPrint('EventChannel error: $err');
        },
      );
    });
  }

  @override
  void dispose() {
    _eventSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;

    // 날짜 또는 검색어 필터
    final filtered = transactions.where((tx) {
      if (_searchKeyword.isNotEmpty) {
        return tx.store.contains(_searchKeyword) ||
            tx.category.contains(_searchKeyword);
      } else {
        final day = _selectedDay ?? _focusedDay;
        return tx.date.year == day.year &&
            tx.date.month == day.month &&
            tx.date.day == day.day;
      }
    }).toList();

    // 날짜별 이벤트 그룹핑 (마커용)
    final Map<DateTime, List<Transaction>> groupedEvents = {};
    for (var tx in transactions) {
      final date = DateTime.utc(tx.date.year, tx.date.month, tx.date.day);
      groupedEvents.update(date, (list) => list..add(tx),
          ifAbsent: () => [tx]);
    }

    void _deleteTransaction(String id) {
      transactionProvider.deleteTransaction(id);
    }

    return Column(
      children: [
        // 월 이동 바
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month - 1);
                }),
              ),
              Text(
                DateFormat.yMMMM('ko_KR').format(_focusedDay),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month + 1);
                }),
              ),
            ],
          ),
        ),

        // 검색창 + 추가 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '검색 (가맹점명 또는 카테고리)',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (value) =>
                        setState(() => _searchKeyword = value),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      selectedDate: _selectedDay ?? _focusedDay,
                    ),
                  ),
                ),
                icon: Icon(Icons.add),
                label: Text('추가'),
                style: ElevatedButton.styleFrom(
                    padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // 달력
        TableCalendar(
          headerVisible: false,
          focusedDay: _focusedDay,
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) => setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          }),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(),
            todayTextStyle:
            TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
            selectedDecoration:
            BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          ),
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          eventLoader: (day) {
            final date = DateTime.utc(day.year, day.month, day.day);
            return groupedEvents[date] ?? [];
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return SizedBox();
              int income = 0, expense = 0;
              for (var e in events) {
                final tx = e as Transaction;
                if (tx.amount >= 0)
                  income += tx.amount;
                else
                  expense += tx.amount.abs();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (income > 0)
                      Text(
                        '+$income',
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    if (expense > 0)
                      Text(
                        '-$expense',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // 테스트용 알림 생성 버튼
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: 10,
                  channelKey: 'basic_channel',
                  title: '테스트 결제1',
                  body: '[Web발신]\n멤버쉽 이용료 4,900원 결제',
                ),
              ),
              child: Text('테스트 알림1'),
            ),
            ElevatedButton(
              onPressed: () => AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: 11,
                  channelKey: 'basic_channel',
                  title: '테스트 결제2',
                  body: '1,760원 원스토어 주식회사 결제완료',
                ),
              ),
              child: Text('테스트 알림2'),
            ),
          ],
        ),

        // 소비 내역 리스트
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('해당 날짜의 소비 내역이 없습니다.'))
              : ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final tx = filtered[i];
              return Card(
                margin:
                EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8, right: 40, bottom: 8, left: 8),
                      child: ListTile(
                        leading: Icon(
                          tx.amount >= 0
                              ? Icons.add_circle
                              : Icons.remove_circle,
                          color: tx.amount >= 0
                              ? Colors.blue
                              : Colors.red,
                        ),
                        title: Text(tx.store),
                        subtitle: Text('${tx.category} • ${tx.type}'),
                        trailing: Text(
                          '${tx.amount >= 0 ? '+' : '-'}${tx.amount.abs()}원',
                          style: TextStyle(
                              color: tx.amount >= 0
                                  ? Colors.blue
                                  : Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.delete,
                            size: 20, color: Colors.grey[600]),
                        onPressed: () => _deleteTransaction(tx.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
