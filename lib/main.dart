import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(CalendarApp());
}

class CalendarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF2F3336),
        fontFamily: 'Montserrat',
      ),
      home: CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _dividends = [];
  bool _showSelectedDateInfo = false;
  List<String> _predefinedTickers = [
    'HGLG11',
    'VISC11',
    'LVBI11',
    'XPLG11'
  ]; // Adicione os ticks predefinidos aqui
  late String _selectedTicker; // Variável para armazenar o ticker selecionado

  @override
  void initState() {
    super.initState();
    _selectedTicker =
        _predefinedTickers.first; // Definir o primeiro ticker como padrão
    _fetchDividends();
  }

  Future<void> _fetchDividends() async {
    final response = await http.get(Uri.parse(
        'https://mfinance.com.br/api/v1/fiis/dividends/$_selectedTicker'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['dividends'] != null) {
        setState(() {
          _dividends = List<Map<String, dynamic>>.from(jsonData['dividends'])
              .where((dividend) =>
                  DateFormat('yyyy-MM').format(
                      DateFormat('yyyy-MM-dd').parse(dividend['payDate'])) ==
                  DateFormat('yyyy-MM').format(_selectedDate))
              .toList();
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _showSelectedDateInfo = true;
      });
      await _fetchDividends();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendário de Dividendos',
          style: TextStyle(fontSize: 16.0),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _showTickerSelectionDialog(context);
            },
            icon: Icon(
                Icons.apartment), // Ícone de predio para representar os tickers
          ),
          IconButton(
            onPressed: () {
              _selectDate(context);
            },
            icon: Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(
            20.0), // Adiciona padding ao redor do calendário
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _buildCalendar(),
            ),
            if (_showSelectedDateInfo) _buildSelectedDateInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final List<TableRow> rows = [];
    final DateTime firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);
    int daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    int currentDay = 1;

    // Header
    rows.add(
      TableRow(
        children: List.generate(7, (index) {
          return _buildWeekDayHeader(index);
        }),
      ),
    );

    // Days
    for (int i = 0; i < 6; i++) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < 7; j++) {
        if ((i == 0 && j < firstDayOfMonth.weekday - 1) ||
            currentDay > daysInMonth) {
          rowChildren.add(Container());
        } else {
          final day =
              DateTime(_selectedDate.year, _selectedDate.month, currentDay);
          rowChildren.add(_buildCalendarDay(day));
          currentDay++;
        }
      }
      rows.add(TableRow(children: rowChildren));
    }

    return Table(children: rows);
  }

  Widget _buildWeekDayHeader(int index) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      child: Text(
        DateFormat('E').format(DateTime(2024, 1, index + 2)),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day) {
    final isCurrentMonth = day.month == _selectedDate.month;
    final isSelectedDay = day.day == _selectedDate.day;
    final hasDividend = _dividends.any((dividend) =>
        DateFormat('yyyy-MM-dd').parse(dividend['payDate']).day == day.day);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = day;
          _showSelectedDateInfo = true;
        });
      },
      child: Container(
        padding: EdgeInsets.all(10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelectedDay
              ? Colors.blue
              : (isCurrentMonth ? Colors.transparent : Colors.grey[800]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelectedDay
                    ? Colors.white
                    : (isCurrentMonth ? Colors.white : Colors.grey[600]),
                fontWeight: isSelectedDay ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasDividend)
              Icon(
                Icons.attach_money,
                color: Colors.yellowAccent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateInfo() {
    final selectedDividends = _dividends
        .where((dividend) =>
            DateFormat('yyyy-MM-dd').parse(dividend['payDate']).day ==
            _selectedDate.day)
        .toList();

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F3336),
              ),
            ),
            SizedBox(height: 20),
            if (selectedDividends.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dividendos:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F3336),
                    ),
                  ),
                  SizedBox(height: 10),
                  ...selectedDividends.map((dividend) {
                    final formattedValue =
                        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                            .format(dividend['value']);
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(15),
                      width: double.infinity, // Occupying full width
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valor: $formattedValue',
                            style: TextStyle(
                                color: Color(0xFF2F3336),
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Data de pagamento: ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(dividend['payDate']))}',
                            style: TextStyle(color: Color(0xFF2F3336)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            if (selectedDividends.isEmpty)
              Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(15),
                width: double.infinity, // Occupying full width
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Nenhum dividendo neste dia.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF2F3336)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTickerSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecionar Ticker'),
          content: SingleChildScrollView(
            child: Column(
              children: _predefinedTickers.map((ticker) {
                return ListTile(
                  title: Text(ticker),
                  onTap: () {
                    setState(() {
                      _selectedTicker = ticker; // Atualiza o ticker selecionado
                      _fetchDividends(); // Busca os dividendos correspondentes ao novo ticker selecionado
                      _showSelectedDateInfo =
                          false; // Oculta as informações da data selecionada para evitar inconsistências
                      Navigator.of(context).pop();
                    });
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
