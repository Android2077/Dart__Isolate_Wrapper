
import 'dart:isolate';



enum enum_PortID
{
  Message,
  Kill,
  SendPort_to_Main,
}


class Isolate_Wrapper__class
{

  //----------------------------------------public:Начало-------------------------------------------------------

  Isolate_Wrapper__class(void Function(String string_error, Isolate_Wrapper__class Isolate_Wrapper__class_ref) Callback_error_)
  {
    _Callback_error = Callback_error_;
  }

  void Run_Isolate(void Function(List<SendPort> vec__SendPort) User_Func_Start_to_Isolate, void Function(dynamic Data_from_Isolate, Isolate_Wrapper__class Isolate_Wrapper__class_, List<Object>? vec__Any_Object) User_Func_RecieveData_from_Isolate, List<Object>? User_Vec__Any_Object)
  {
    if (active_flag == false)
    {
      //------------------------------------------------------
      _Main_receivePort = ReceivePort();
      _Service_receivePort_Kill = ReceivePort();
      _Service_receivePort_Isolate_SendPort = ReceivePort();
      _OnExit_receivePort_ = ReceivePort();
      _OnError_receivePort_ = ReceivePort();

      _User_Vec__Any_Object = User_Vec__Any_Object;
      _User_Func_RecieveData_from_Isolate = User_Func_RecieveData_from_Isolate;
      //------------------------------------------------------

      _isolate_run(User_Func_Start_to_Isolate);
    }
  }

  void Isolate_kill()
  {
    if (active_flag == true)
    {
      _isolate.kill();

      _Main_receivePort.close();
      _Service_receivePort_Kill.close();
      _Service_receivePort_Isolate_SendPort.close();
      _OnExit_receivePort_.close();
      _OnError_receivePort_.close();

      _SendPort_from_Isolate       = null;
      _User_Vec__Any_Object        = null;

      _List_delayed_send_to_Isolate.clear();

      active_flag = false;
    }
  }

  void Send_Message_to_Isolate(dynamic dynamic_Object)
  {
    if (_SendPort_from_Isolate == null)
    {
      _List_delayed_send_to_Isolate.add(dynamic_Object); //Значит Пользовтаель вызвал отправку данных в Изолят еще До получения SendPort`а из Изолята, поэтому доавбим данные для отправки в вектор ожидания и отправим их, когда из Изолята придет SendPort - то есть в функции "_Recieve_SendPort_from_Isolate__handler"
    }
    else
    {
      _SendPort_from_Isolate!.send(dynamic_Object); //Отправляем данные в Изолят, если _SendPort_from_Isolate не null.
    }
  }

  bool get__Isolate_status()
  {
    return active_flag;
  }

  //----------------------------------------public:Конец-------------------------------------------------------


  //----------------------------------------private:Начало----------------------------------------------------
  late ReceivePort _Main_receivePort;
  late ReceivePort _Service_receivePort_Kill;
  late ReceivePort _Service_receivePort_Isolate_SendPort;
  late ReceivePort _OnExit_receivePort_;
  late ReceivePort _OnError_receivePort_;

  late Future<Isolate> _isolate_Future;
  late Isolate _isolate;

  List<Object>? _User_Vec__Any_Object = [];
  late void Function(dynamic Data_from_Isolate, Isolate_Wrapper__class Isolate_Wrapper__class_, List<Object>? User_Vec__Any_Object) _User_Func_RecieveData_from_Isolate;

  late SendPort? _SendPort_from_Isolate = null;

  late void Function(String string_error, Isolate_Wrapper__class Isolate_Wrapper__class_ref) _Callback_error;

  List<dynamic> _List_delayed_send_to_Isolate = [];

  bool active_flag = false;

  //----------------------------------------private:Начало----------------------------------------------------


  //----------------------------------------private:Начало----------------------------------------------------
  void _isolate_run(void Function(List<SendPort> vec__SendPort) User_Func_Start_to_Isolate) async
  {
    _isolate_Future = Isolate.spawn(User_Func_Start_to_Isolate, [_Main_receivePort.sendPort, _Service_receivePort_Kill.sendPort, _Service_receivePort_Isolate_SendPort.sendPort], onExit: _OnExit_receivePort_.sendPort, onError: _OnError_receivePort_.sendPort); // Запускаем изолят, передавая ему Функция для исполнения и SendPort главного потока

    _isolate = await _isolate_Future; //Ждем пока Изолят создатся после вызова "spawn" и возвратится обьект Изолята к которому потом можно обращатся.


    _Main_receivePort.listen(_Func_RecieveData_from_Isolate); //Слушаем входящие данные. Функция "Func_RecieveData_from_Isolate" будет вызывается каждый раз, как из Изоялта будет пересылтся какое либо сообщение по переданному в нее "receivePort.sendPort".

    _Service_receivePort_Kill.listen(_Kill_Isolate__handler);

    _Service_receivePort_Isolate_SendPort.listen(_Recieve_SendPort_from_Isolate__handler);

    _OnExit_receivePort_.listen(_OnExit__handler);

    _OnError_receivePort_.listen(_OnError__handler);


    active_flag = true;
  }

  //----------------------------------------private:Конец----------------------------------------------------


  //----------------------------------------private:Начало----------------------------------------------------
  void _Func_RecieveData_from_Isolate(dynamic Data_from_Isolate)
  {
    //Данная функция будет вызыватся каждый раз, как из функции "Func_Start_to_Isolate" будут переданы данные из Изолята в поток через вызов "SendPort_from_Recieve.send()", который этот Изолят создан, и этот поток вызовет эту функцию.
    //Data_from_Isolate - это данные переданные из функции "Func_Start_to_Isolate" через "SendPort_from_Recieve.send()".

    _User_Func_RecieveData_from_Isolate(Data_from_Isolate, this, _User_Vec__Any_Object); //Вызываем Пользовательскую функцию.  Передаем в нее ссылку на сами переданные данные из Изоялта и ссылку на данный класс.
  }

  void _Kill_Isolate__handler(dynamic Data_from_Isolate)
  {
    //Если пришло любое сообщение по этому порту, значит Пользователь хочет закрыть Изолят.

    Isolate_kill();
  }

  void _Recieve_SendPort_from_Isolate__handler(dynamic Data_from_Isolate)
  {
    //Значит Пользователь прислал SendPort из Изолята, чтобы можно было пересылать данные в Изолят.

    if (Data_from_Isolate is SendPort == true)
    {
      _SendPort_from_Isolate = Data_from_Isolate;

      if (_List_delayed_send_to_Isolate.length > 0)
      {
        //Отрпавим все данные из вектора ожидания в Изолят:

        for (int i = 0; i < _List_delayed_send_to_Isolate.length; i++)
        {
          Send_Message_to_Isolate(_List_delayed_send_to_Isolate[i]);
        }

        _List_delayed_send_to_Isolate.clear();
      }
    }
  }

//----------------------------------------private:Начало----------------------------------------------------


  //----------------------------------------private:Начало----------------------------------------------------
  void _OnExit__handler(dynamic Data_from_Isolate)
  {
    //Сообщение на данный порт приходит единожды при закрытии Изолята, сообщенеи приходит автоматчески от Dart`а - и говорит о том, что Изолят уже завершен, то есть функция в изоляте завершилась.

    Isolate_kill();
  }


  void _OnError__handler(dynamic Data_from_Isolate)
  {
    //Сообщение на данный порт приходит в случае каких либо ошибок в Изоляте

    String String_error = "";

    for (int i = 0; i < Data_from_Isolate.length; i++)
    {
      String_error = String_error + ":" + Data_from_Isolate[i];
    }

    _Callback_error(String_error, this);
  }
//----------------------------------------private:Начало----------------------------------------------------


}

