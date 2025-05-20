import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/auth_provider.dart';
import '../../utils/animations.dart';
import '../../utils/text_utils.dart';

import '../../data/bg_data.dart';
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int selectedIndex = 0;
  bool showOption = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Container(
        margin:const  EdgeInsets.symmetric(vertical: 10),
        height: 49,
        width: double.infinity,

        child: Row(
          children: [
            Expanded(
                child:showOption? ShowUpAnimation(
                  delay: 100,
                  child: ListView.builder(
                    shrinkWrap: true,
                      itemCount: bgList.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context,index){
                   return   GestureDetector(
                     onTap: (){
                       setState(() {
                         selectedIndex=index;
                       });
                     },
                     child: CircleAvatar(
                       radius: 30,

                       backgroundColor:selectedIndex==index? Colors.white:Colors.transparent,
                       child: Padding(
                         padding:const  EdgeInsets.all(1),
                         child: CircleAvatar(
                           radius: 30,
                           backgroundImage: AssetImage(bgList[index],),
                         ),
                       ),
                     ),
                   );

                  }),
                ):const SizedBox()),
           const  SizedBox(width: 20,),
           showOption? GestureDetector(
             onTap: (){
               setState(() {
                 showOption=false;
               });
             },
               child:const  Icon(Icons.close,color: Colors.white,size: 30,)) :
           GestureDetector(
             onTap: (){
               setState(() {
                 showOption=true;
               });
             },
             child: CircleAvatar(

                backgroundColor: Colors.white,
                child: Padding(
                  padding:const  EdgeInsets.all(1),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(bgList[selectedIndex],),
             ),
                ),
              ),
           )
          ],
        ),
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
        decoration:  BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgList[selectedIndex]),fit: BoxFit.fill
          ),

        ),
    alignment: Alignment.center,
    child: Container(
      height: 500,
      width: 400,
        margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        color: Colors.black.withOpacity(0.1),


        ),
      child: ClipRRect(

        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(filter:ImageFilter.blur(sigmaY: 5,sigmaX: 5),
    child:Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const   Spacer(),
          Center(child: TextUtil(text: "Login",weight: true,size: 30,)),
          const   Spacer(),
          TextUtil(text: "Username",),
          Container(
            height: 35,
            decoration:const  BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white))
            ),
            child:TextFormField(
              style: const TextStyle(color: Colors.white),
              controller: _usernameController,
              decoration:const  InputDecoration(
                suffixIcon: Icon(Icons.person,color: Colors.white,),
               fillColor: Colors.white,
                border: InputBorder.none,),
            ),
          ),
          const   Spacer(),
          TextUtil(text: "Password",),
          Container(
            height: 35,
            decoration:const  BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white))
            ),
            child:TextFormField(
              style: const TextStyle(color: Colors.white),
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
            ),
          ),
          const   Spacer(),
          Center(
            child: ElevatedButton(
              onPressed: ()async{
                final username = _usernameController.text;
                final password = _passwordController.text;
            
                try {
                  await ref.read(authProvider.notifier).login(username, password);
                  
                  Navigator.pushReplacementNamed(context, "/dashboard");
                }
                catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid credentials")),
                  );
                }
            },
            style: ButtonStyle(
              fixedSize: WidgetStateProperty.all<Size> (
                Size(200, 40),
              )
            ),
            child: TextUtil(text: "Log In",color: Colors.black,),
            ),
          ),
       const   Spacer(),
        ],
      ),
    ) ),
      ),
      ),


    ),



       );
  }
}
