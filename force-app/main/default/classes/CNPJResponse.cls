public class CNPJResponse {
    public String updated;
    public String taxId;
    public String alias;
    public String founded;
    public Boolean head;
    public Company company;
    public Status status;
    public Address address;
    public MainActivity mainActivity;
    public List<Phone> phones;
    public List<Email> emails;
    public List<Registration> registrations;

    public class Company {
        public Integer id;
        public String name;
        public Decimal equity;
        public Nature nature;
        public Size size;
        public Simples simples;
        public Simei simei;
        public List<Member> members;
    }

    public class Member {
        public String since;
        public Person person;
        public Role role;
    }

    public class Person {
        public String id;
        public String type;
        public String name;
        public String taxId;
        public String age;
    }

    public class Role {
        public Integer id;
        public String text;
    }

    public class Nature {
        public Integer id;
        public String text;
    }

    public class Size {
        public Integer id;
        public String acronym;
        public String text;
    }

    public class Simples {
        public Boolean optant;
        public String since;
    }

    public class Simei {
        public Boolean optant;
        public String since;
    }

    public class Status {
        public Integer id;
        public String text;
    }

    public class Address {
        public Integer municipality;
        public String street;
        public String streetNumber;
        public String district;
        public String city;
        public String state;
        public String details;
        public String zip;
        public Country country;
    }

    public class Country {
        public Integer id;
        public String name;
    }

    public class MainActivity {
        public Integer id;
        public String text;
    }

    public class Phone {
        public String type;
        public String area;
        public String phoneNumber;
    }

    public class Email {
        public String ownership;
        public String address;
        public String domain;
    }

    public class Registration {
        public String registrationNumber;
        public String state;
        public Boolean enabled;
        public String statusDate;
        public RegistrationStatus status;
        public RegistrationType type;
    }

    public class RegistrationStatus {
        public Integer id;
        public String text;
    }

    public class RegistrationType {
        public Integer id;
        public String text;
    }
}