import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../providers/TransactionProvider.dart';
import '../models/Transaction.dart';
import 'AddTransactionScreen.dart';


class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _searchKeyword = ''; // 검색어 상태 변수

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;

    // 날짜 + 검색 필터
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
    Map<DateTime, List<Transaction>> groupedEvents = {};
    for (var tx in transactions) {
      final date = DateTime.utc(tx.date.year, tx.date.month, tx.date.day);
      groupedEvents.update(date, (list) => list..add(tx), ifAbsent: () => [tx]);
    }

    void _deleteTransaction(String id) {
      transactionProvider.deleteTransaction(id);
    }

    return Column(
      children: [
        // 🗓 커스텀 달 이동 바
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
              ),
              Text(
                DateFormat.yMMMM('ko_KR').format(_focusedDay),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '검색 (내역이름 또는 카테고리)',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchKeyword = value;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(
                        selectedDate: _selectedDay ?? _focusedDay,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('추가'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),

            ],
          ),
        ),

        SizedBox(height: 16,),

        // 캘린더
        TableCalendar(
          headerVisible: false,
          focusedDay: _focusedDay,
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(), // 파란색 원 제거
            todayTextStyle: TextStyle( // 오늘 날짜 숫자 보이게 처리
              color: Colors.black,     // 원하는 색상으로 설정
              fontWeight: FontWeight.normal,
            ),
            selectedDecoration:
            BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          ),
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
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

        ElevatedButton(
          onPressed: () {
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: 1,
                channelKey: 'basic_channel',
                title: '토스',
                body: '1,760원 원스토어 주식회사 결제완료 | 토스머니 잔액 3000원 | 캐시백 10%는 다음 기회에',
              ),
            );
          },
          child: Text('알림 테스트1 토스'),
        ),

        ElevatedButton(
          onPressed: () {
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: 1,
                channelKey: 'basic_channel',
                title: '9원 캐시백',
                body: '3,300원 결제 | 지에스25 뉴호서대후문점 잔액 1,000원(토스뱅크 체크카드)',
              ),
            );
          },
          child: Text('알림 테스트2 토스'),
        ),

        ElevatedButton(
          onPressed: () {
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: 1,
                channelKey: 'basic_channel',
                title: '메시지',
                body: '[Web발신]\n[네이버플러스] 멤버쉽 이용료 4,900원 결제',
              ),
            );
          },
          child: Text('알림 테스트3 메시지(네이버)'),
        ),

        ElevatedButton(
          onPressed: () {
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: 1,
                channelKey: 'basic_channel',
                title: 'SK텔레콤',
                body: '[Web발신]결\n결제 일시 2025/0703 10:37\n결제 금액 4,900원\n서비스명 네이버페이\n상품명 NV네이버플러스\n문의처\n사용처\n네이버파이낸셜 주식회사\n사용처 연락처 1588-3820...',
              ),
            );
          },
          child: Text('알림 테스트4 메시지(SK텔레콤 네이버플러스)'),
        ),

        ElevatedButton(
          onPressed: () {
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: 1,
                channelKey: 'basic_channel',
                title: 'KB국민카드',
                body: '[Web]발신\n[KB국민체크]맹동훈님 교통대금 5,200원 07/03 체크결제계좌에서 출금예정(07/02기준)',
              ),
            );
          },
          child: Text('알림 테스트5 메시지(KB국민카드)'),
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
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 40, bottom: 8, left: 8),
                      child: ListTile(
                        leading: Icon(
                          tx.amount >= 0 ? Icons.add_circle : Icons.remove_circle,
                          color: tx.amount >= 0 ? Colors.blue : Colors.red,
                        ),
                        title: Text(tx.store),
                        subtitle: Text(tx.category),
                        trailing: Text(
                          '${tx.amount >= 0 ? '+' : '-'}${tx.amount.abs()}원',
                          style: TextStyle(
                            color: tx.amount >= 0 ? Colors.blue : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.delete, size: 20, color: Colors.grey[600]),
                        onPressed: () {
                          _deleteTransaction(tx.id);
                        },
                      ),
                    ),
                  ],
                ),
              );

            },
          ),
        )

      ],
    );
  }
}
