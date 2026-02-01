public class ExternalProductPayload {

    public List<Product> products;

    public class Product {
        public Integer id;
        public String title;
        public Decimal price;
        public String category;
        public String image;
    }
}
