import 'package:floor/floor.dart';
import 'customer_list.dart';

@dao
abstract class CustomerDao {
  @Query('SELECT * FROM Customer')
  Future<List<Customer>> getAllCustomers();

  @insert
  Future<void> insertCustomer(Customer customer);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateCustomer(Customer customer);

  @Query('DELETE FROM Customer WHERE id = :id')
  Future<void> deleteCustomerById(int id);
}
