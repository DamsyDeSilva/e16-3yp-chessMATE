import 'package:chessMATE_app/login/login_validate.dart';
import 'package:flutter_test/flutter_test.dart';

void main(){

// test the email address validation function
  group('Test the email address ', () {
    // test for invalid email address
    test('Invalid email address returns false', (){

      bool result1 = validate_email( "a");
    expect(result1,false);

    });
    
    // test for valid email address
    test('Valid email address returns true', (){

      bool result2 = validate_email( "abc@gmail.com");
      expect(result2,true);

    }); 

  });

// test the password validation function
 group('Test the password', () {

   // test for invalid password
   test('Invalid password returns false', (){
    bool result1 = validate_password( "a1");
    expect(result1,false);
   });

  // test for valid password
  test('Valid password returns true', (){
    bool result2 = validate_password( "ab&1");
    expect(result2,true);
   });  
  });

/*
4 --> sucessful login
2 --> both email and password are invalid
1 --> password is invalid
0 --> email is invalid
*/

// test login validation function

  group('Test the Login', () {

    test('Both email and passwords are invalid', (){

      int result1 = validate_login("", "" );
      expect(result1,2);

    });

    test('Password is invalid', (){
      int result2 = validate_login( "abc@gmail.com", "11");
      expect(result2,1);

    });

    test('Email is invalid', (){

      int result3 = validate_login( "abc@gm", "ab#12");
      expect(result3,0);

    });

    test('Both email and password are valid', (){
      int result4 = validate_login( "abc@gmail.com", "abc123");
      expect(result4,4);

    });

     

    

    

    
  });



}