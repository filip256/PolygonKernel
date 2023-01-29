#include <SFML/Graphics.hpp>
#include <iostream>
#include <fstream>
#include <string>
#include <windows.h>

#define NAN 32767
#define INFINITE 10100
#define WIN_WIDTH 1000
#define WIN_HEIGHT 1000

inline void pause(sf::RenderWindow& window)
{
	std::cout << "PAUSE\n";
	while (window.isOpen())
	{
		sf::Event event;
		while (window.pollEvent(event))
		{
			if (event.type == sf::Event::KeyPressed && sf::Keyboard::isKeyPressed(sf::Keyboard::Space))
				return;
			else if (event.type == sf::Event::Closed)
				window.close();
		}
	}
}

inline float round2(const float f)
{
	return static_cast<float>(static_cast<int>(f * 100)) / 100.0;
}

std::string openFileDialog(const HWND& hwnd)
{
	char path[512] = {0};
	OPENFILENAMEA _ofn = { sizeof(OPENFILENAMEA) };
	_ofn.hwndOwner = hwnd;
	_ofn.lpstrTitle = "Open File";
	_ofn.lpstrFilter = "All files\0*.*\0";
	_ofn.lpstrDefExt = "txt";
	_ofn.lpstrFile = path;
	_ofn.nMaxFile = 512;
	_ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST;

	GetOpenFileNameA(&_ofn);

	return path;
}

namespace geo
{
	class Vertex
	{
	public:
		float x, y;

		Vertex() :
			x(NAN),
			y(NAN)
		{}

		Vertex(const float xCoord, const float yCoord) :
			x(round2(xCoord)),
			y(round2(yCoord))
		{}

		inline static bool exists(const Vertex& v) { return v.x == NAN || v.y == NAN; }

		void draw(sf::RenderWindow& window, const char marker = 'a') const
		{
			sf::Vertex v(sf::Vector2f(x, y), sf::Color(255, 215, 0, 255));
			window.draw(&v, 1, sf::Points);
			if (marker == 'c')
			{
				sf::CircleShape circle(4.0, 8);
				circle.setOrigin(sf::Vector2f(4.0, 4.0));
				circle.setFillColor(sf::Color(255, 215, 0, 100));
				circle.setOutlineColor(sf::Color(255, 215, 0, 255));
				circle.setOutlineThickness(1);
				circle.setPosition(v.position);
				window.draw(circle);
			}
			else if (marker == 's')
			{
				sf::CircleShape circle(8.0, 4);
				circle.setOrigin(sf::Vector2f(8.0, 8.0));
				circle.setFillColor(sf::Color(10, 55, 255, 100));
				circle.setOutlineColor(sf::Color(10, 55, 255, 255));
				circle.setOutlineThickness(1);
				circle.setPosition(v.position);
				window.draw(circle);
			}
			else if (marker == 't')
			{
				sf::CircleShape circle(6.0, 3);
				circle.setOrigin(sf::Vector2f(6.0, 6.0));
				circle.setFillColor(sf::Color(255, 10, 10, 100));
				circle.setOutlineColor(sf::Color(255, 10, 10, 255));
				circle.setOutlineThickness(1);
				circle.setPosition(v.position);
				window.draw(circle);
			}
		}
		void draw(sf::RenderWindow& window, const sf::Color& color, const char marker = 'a') const
		{
			sf::Vertex v(sf::Vector2f(x, y), color);
			window.draw(&v, 1, sf::Points);
			if (marker == 'c')
			{
				sf::CircleShape circle(4.0, 8);
				circle.setOrigin(sf::Vector2f(4.0, 4.0));
				circle.setFillColor(sf::Color(color.r, color.g, color.b, 100));
				circle.setOutlineColor(color);
				circle.setOutlineThickness(1);
				circle.setPosition(v.position);
				window.draw(circle);
			}
			else if (marker == 's')
			{
				sf::CircleShape circle(8.0, 4);
				circle.setOrigin(sf::Vector2f(8.0, 8.0));
				circle.setFillColor(sf::Color(color.r, color.g, color.b, 100));
				circle.setOutlineColor(color);
				circle.setOutlineThickness(1);
				circle.setPosition(v.position);
				window.draw(circle);
			}
			else if (marker == 't')
			{
				sf::CircleShape circle(6.0, 3);
				circle.setOrigin(sf::Vector2f(6.0, 6.0));
				circle.setFillColor(sf::Color(color.r, color.g, color.b, 100));
				circle.setOutlineColor(color);
				circle.setOutlineThickness(1);
				circle.setPosition(v.position);
				window.draw(circle);
			}
		}

		static const Vertex NullVertex;
	};
	const Vertex Vertex::NullVertex(NAN, NAN);

	void drawLine(const Vertex& v1, const Vertex& v2, sf::RenderWindow& window)
	{
		sf::Vertex line[2];
		line[0].position = sf::Vector2f(v1.x, v1.y);
		line[1].position = sf::Vector2f(v2.x, v2.y);
		window.draw(line, 2, sf::Lines);
	}

	static inline bool operator==(const Vertex& lhs, const Vertex& rhs) { return lhs.x == rhs.x && lhs.y == rhs.y; }
	static inline bool operator!=(const Vertex& lhs, const Vertex& rhs) { return lhs.x != rhs.x || lhs.y != rhs.y; }

	class Equation
	{
		bool isVertical = false;
		float a, c;

		static bool onSegment(const Vertex& p, const Vertex& q, const Vertex& r)
		{
			if (q.x <= std::max(p.x, r.x) && q.x >= std::min(p.x, r.x) &&
				q.y <= std::max(p.y, r.y) && q.y >= std::min(p.y, r.y))
				return true;

			return false;
		}
		static int orientation(const Vertex& p, const Vertex& q, const Vertex& r)
		{
			int val = (q.y - p.y) * (r.x - q.x) -
				(q.x - p.x) * (r.y - q.y);

			if (val == 0) return 0;

			return (val > 0) ? 1 : 2;
		}

	public:
		Equation(const Vertex& v1, const Vertex& v2)
		{
			if (v1.x == v2.x)
			{
				isVertical = true;
				c = v1.x;
			}
			else
			{
				a = (v2.y - v1.y) / (v2.x - v1.x);
				c = v1.y - a * v1.x;
			}
		}

		float getY(const float x) const { return isVertical ? INFINITE : a * x + c; }
		float getX(const float y) const { return isVertical ? c : (y - c) / a; }

		Vertex intersect(const Equation& other) const
		{
			//std::cout << "a1=" << a << " c1=" << c << "   a2=" << other.a << " c2=" << other.c<<'\n';
			if (isVertical)
				return Vertex(c, other.getY(c));
			if (other.isVertical)
				return Vertex(other.c, getY(other.c));

			return a == other.a ? Vertex::NullVertex
				: Vertex((other.c - c) / (a - other.a), (other.c * a - c * other.a) / (a - other.a));
		}
		Vertex intersect(const Vertex& v1, const Vertex& v2) const
		{
			const Vertex temp = intersect(Equation(v1, v2));
			if(v1.x != v2.x && !isVertical)
				return (temp.x >= v1.x && temp.x <= v2.x) || (temp.x >= v2.x && temp.x <= v1.x) ? temp : Vertex::NullVertex;
			else
				return (temp.y >= v1.y && temp.y <= v2.y) || (temp.y >= v2.y && temp.y <= v1.y) ? temp : Vertex::NullVertex;
		}

		void draw(sf::RenderWindow& window) const
		{
			sf::Vertex line[2];
			line[0].color = line[1].color = sf::Color(255, 255, 255, 150);

			if (isVertical)
			{
				for (float i = -10; i < 1010; i += 20)
				{
					line[0].position = sf::Vector2f(c, i);
					line[1].position = sf::Vector2f(c, i + 10);
					window.draw(line, 2, sf::Lines);
				}
			}
			else
			{
				const float step = 20 / abs(a), halfStep = step / 2.0;
				for (float i = -10; i < 1010; i += step)
				{
					line[0].position = sf::Vector2f(i, getY(i));
					line[1].position = sf::Vector2f(i + halfStep, getY(i + halfStep));
					window.draw(line, 2, sf::Lines);
				}
			}
		}

		static Vertex toInfinite(const Vertex& first, const Vertex& second)
		{
			const Equation e(first, second);
			if (e.isVertical)
				return first.y <= second.y ? Vertex(first.x, INFINITE) : Vertex(first.x, -INFINITE);
			else
				return first.x <= second.x ? Vertex(INFINITE, e.getY(INFINITE)) : Vertex(-INFINITE, e.getY(-INFINITE));
		}

		static bool doIntersect(const Vertex& p1, const Vertex& q1, const Vertex& p2, const Vertex& q2)
		{
			int o1 = orientation(p1, q1, p2);
			int o2 = orientation(p1, q1, q2);
			int o3 = orientation(p2, q2, p1);
			int o4 = orientation(p2, q2, q1);

			if (o1 != o2 && o3 != o4)
				return true;

			if (o1 == 0 && onSegment(p1, p2, q1)) return true;

			if (o2 == 0 && onSegment(p1, q2, q1)) return true;

			if (o3 == 0 && onSegment(p2, p1, q2)) return true;

			if (o4 == 0 && onSegment(p2, q1, q2)) return true;

			return false;
		}
	};

	template <class T>
	class CyclicVector
	{
		std::vector<T> vector;

	public:
		CyclicVector(const size_t expectedSize = 8)
		{
			vector.reserve(expectedSize);
		}

		inline size_t size() const { return vector.size(); }
		inline const T& back() const { return vector.back(); }
		inline const T& front() const { return vector.front(); }
		inline const std::vector<T>& getVector() const { return vector; }

		inline void push_back(const T& obj)
		{
			vector.push_back(obj);
		}
		inline void pop_back()
		{
			vector.pop_back();
		}
		inline void clear()
		{
			vector.clear();
		}
		inline void insert(const size_t index, const T& obj)
		{
			//std::cout << "insert: " << index << ' ' << size() << '\n';
			vector.insert(vector.begin() + index, obj);
		}
		inline void erase(const size_t start, const size_t end = start + 1)
		{
			//std::cout << "delete: " << start << ' ' << end << ' ' << size() << '\n';
			vector.erase(vector.begin() + start, vector.begin() + end);
		}
		inline void reserve(const size_t size)
		{
			vector.reserve(size);
		}

		T& operator[](const long idx) { return vector[mapIndex(idx)]; }
		const T& operator[](const long idx) const { return vector[mapIndex(idx)]; }

		inline size_t mapIndex(const long idx) const { return idx >= 0 ? idx % vector.size() : idx + (vector.size() * (-idx / vector.size() + 1)); }
	};

	class Kernel
	{
		CyclicVector<Vertex> vertices;
		size_t F = NAN, L = NAN;

	public:
		Kernel()
		{}

		Kernel(const Vertex& v1, const Vertex& v2, const Vertex& v3, const size_t expectedSize = 8) :
			L(0),
			F(2)
		{
			vertices.reserve(expectedSize);
			vertices.push_back(v1);
			vertices.push_back(v2);
			vertices.push_back(v3);
		}

		Kernel(const CyclicVector<Vertex>& vertexVector) :
			vertices(vertexVector)
		{}

		inline const size_t size() const { return vertices.size(); }
		inline const Vertex& getF() const { return vertices[F]; }
		inline const Vertex& getL() const { return vertices[L]; }
		inline const size_t indexOfF() const { return F; }
		inline const size_t indexOfL() const { return L; }

		void addVertex(const Vertex& vertex)
		{
			vertices.push_back(vertex);
		}
		void cut(const size_t idx1, const Vertex& v1, const size_t idx2, const Vertex& v2, const bool otherSide = false)
		{
			if (idx1 == idx2)
				return;

			std::cout << idx1 << " " << idx2 << '\n';
			if (otherSide)
			{
				std::cout << "A\n";
				vertices.insert(idx1 + 1, v1);
				vertices.insert(idx2 + 2, v2);
				vertices.erase(idx2 + 3, vertices.size());
				vertices.erase(0, idx1 + 1);
				F = idx2 + 1;
				L = idx2;
				return;
			}

			std::cout << "B\n";
			vertices.insert(idx1 + 1, v1);
			vertices.insert(idx2 + 2, v2);
			vertices.erase(idx1 + 2, idx2 + 2);


			F = idx1 + 2;
			L = idx2;
		}

		void draw(sf::RenderWindow& window) const
		{
			if (vertices.size() >= 3)
			{
				sf::Vertex vert[3];
				vert[0].color = vert[1].color = vert[2].color = sf::Color(182, 112, 255, 80);
				vert[0].position = sf::Vector2f(vertices[0].x, vertices[0].y);
				for (size_t i = 1; i < vertices.size() - 1; ++i)
				{
					vert[1].position = sf::Vector2f(vertices[i].x, vertices[i].y);
					vert[2].position = sf::Vector2f(vertices[i + 1].x, vertices[i + 1].y);
					window.draw(vert, 3, sf::Triangles);
				}

				vert[0].color = vert[1].color = sf::Color(182, 112, 255, 255);
				for (size_t i = 0; i < vertices.size() - 1; ++i)
				{
					vert[0].position = sf::Vector2f(vertices[i].x, vertices[i].y);
					vert[1].position = sf::Vector2f(vertices[i + 1].x, vertices[i + 1].y);
					window.draw(vert, 2, sf::Lines);
				}
				vert[0].position = sf::Vector2f(vertices[0].x, vertices[0].y);
				vert[1].position = sf::Vector2f(vertices.back().x, vertices.back().y);
				window.draw(vert, 2, sf::Lines);
			}
		}

		Vertex& operator[](const long idx) { return vertices[idx]; }
		const Vertex& operator[](const long idx) const { return vertices[idx]; }

		inline size_t mapIndex(const long idx) const { return vertices.mapIndex(idx); }

		static const Kernel NullKernel;
	};
	const Kernel Kernel::NullKernel;

	class Polygon
	{
		bool isValid = false;
		bool isNormalized = true;
		CyclicVector<Vertex> vertices;

		bool isClockwise() const
		{
			float area = 0.0;
			if (vertices.size() > 2)
			{
				for (size_t i = 0; i < vertices.size() - 1; ++i)
					area += -vertices[i].y * vertices[i + 1].x + vertices[i].x * vertices[i + 1].y;
				area += -vertices.back().y * vertices.front().x + vertices.back().x * vertices.front().y;
			}
			return area >= 0;
		}

		void checkValid()
		{
			if (vertices.size() < 3)
			{
				isValid = false;
				return;
			}

			for (size_t i = 0; i < vertices.size() - 1; ++i)
			{
				for (size_t j = i + 2; j < vertices.size() - 1; ++j)
					if (Equation::doIntersect(vertices[i], vertices[i + 1], vertices[j], vertices[j + 1]))
					{
						isValid = false;
						return;
					}
				if (vertices.size() > 3 && Equation::doIntersect(vertices[i], vertices[i + 1], vertices[i - 1], vertices[i - 2]))
				{
					isValid = false;
					return;
				}
			}

			isValid = true;
		}

		size_t findReflexVertex() const
		{
			if (isReflex(vertices.back(), vertices.front(), vertices[1]))
				return 0;

			for (size_t i = 0; i < vertices.size() - 2; ++i)
				if (isReflex(vertices[i], vertices[i + 1], vertices[i + 2]))
					return i + 1;

			if (isReflex(vertices[vertices.size() - 2], vertices.back(), vertices.front()))
				return vertices.size() - 1;

			return vertices.size();
		}

	public:
		void addVertex(const Vertex& vertex)
		{
			vertices.push_back(vertex);
			isNormalized = false;
			checkValid();
		}

		void popVertex(const size_t idx)
		{
			if (idx >= vertices.size()) 
				return;
				
			vertices.erase(idx, idx + 1);
			isNormalized = false;
			checkValid();
		}
		void clear()
		{
			isNormalized = true;
			isValid = false;
			vertices.clear();
		}

		inline size_t size() const { return vertices.size(); }

		size_t find(const sf::Vector2f& point)
		{
			for (size_t i = 0; i < vertices.size(); ++i)
				if ((point.x - vertices[i].x) * (point.x - vertices[i].x) + (point.y - vertices[i].y) * (point.y - vertices[i].y) < 64)
					return i;
			return NAN;
		}
		inline void setPosition(const size_t idx, const sf::Vector2f& position)
		{
			vertices[idx].x = position.x;
			vertices[idx].y = position.y;
			checkValid();
		}

		void normalize()
		{
			if (isNormalized)
				return;
			if (isClockwise())
			{
				for (size_t i = 0; i < vertices.size() / 2; ++i)
					std::swap(vertices[i], vertices[vertices.size() - i - 1]);
			}
			isNormalized = true;
		}

		Kernel getKernel()
		{
			if (!isValid)
				return Kernel::NullKernel;
			if (vertices.size() == 3)
				return Kernel(vertices[0], vertices[1], vertices[2], 3);

			normalize();

			const size_t first = findReflexVertex();
			if (first == vertices.size()) // polygon is convex
				return Kernel(vertices);

			// - Lee & Preparata -
			Kernel K(
				Equation::toInfinite(vertices[first + 1], vertices[first]),
				vertices[first],
				Equation::toInfinite(vertices[first - 1], vertices[first])
			);

			for (size_t i = first + 1; vertices.mapIndex(i + 1) != first; ++i)
			{
				Equation E(vertices[i], vertices[i + 1]);

				//if (crossProduct(vertices[i], vertices[i + 1], K.getF()) > 0)
				//	continue;

				Vertex W1, W2;
				size_t j = 0, intIdx1 = 0, intIdx2 = 0;
				while (j < K.size())
				{
					W1 = E.intersect(K[j], K[j + 1]);
					if (W1 != Vertex::NullVertex)
					{
						intIdx1 = j;
						break;
					}
					++j;
				}
				if (W1 == Vertex::NullVertex)
					//return Kernel::NullKernel;
					continue;
				++j;
				while (j < K.size())
				{
					W2 = E.intersect(K[j], K[j + 1]);
					if (W2 != Vertex::NullVertex)
					{
						intIdx2 = j;
						break;
					}
					++j;
				}

				K.cut(intIdx1, W1, intIdx2, W2, crossProduct(vertices[i], vertices[i + 1], K[0]) > 0);
			}
			return K;
		}

		Kernel getKernel(sf::RenderWindow& window)
		{
			if (!isValid)
				return Kernel::NullKernel;
			if (vertices.size() == 3)
				return Kernel(vertices[0], vertices[1], vertices[2], 3);

			normalize();

			const size_t first = findReflexVertex();
			if (first == vertices.size()) // polygon is convex
				return Kernel(vertices);

			// - Lee & Preparata -
			Kernel K(
				Equation::toInfinite(vertices[first + 1], vertices[first]),
				vertices[first],
				Equation::toInfinite(vertices[first - 1], vertices[first])
			);

			std::cout << "Start: V" << first<<'\n';
			for (size_t i = first + 1; vertices.mapIndex(i + 1) != first; ++i)
			{
				window.clear();
				draw(window);
				Equation E(vertices[i], vertices[i + 1]);
				E.draw(window);
				K.draw(window);
				window.display();

				//if (crossProduct(vertices[i], vertices[i + 1], K[0]) > 0)
				//	continue;

				Vertex W1, W2;
				size_t j = 0, intIdx1 = 0, intIdx2 = 0;
				while(j < K.size())
				{
					W1 = E.intersect(K[j], K[j + 1]);
					if (W1 != Vertex::NullVertex)
					{
						intIdx1 = j;
						std::cout << "W1 found between " << j << "-" << j + 1 << '\n';
						break;
					}
					++j;
				}
				if (W1 == Vertex::NullVertex)
					//return Kernel::NullKernel;
					continue;
				++j;
				while (j < K.size())
				{
					std::cout << j << '\n';
					W2 = E.intersect(K[j], K[j + 1]);
					if (W2 != Vertex::NullVertex)
					{
						intIdx2 = j;
						std::cout << "W2 found between " << j << "-" << j + 1 << '\n';
						break;	
					}
					++j;
				}
				std::cout << intIdx1 << " " << intIdx2 <<" "<<K.size()<< '\n';
				W1.draw(window, 'c');
				W2.draw(window, 's');
				window.display();
				pause(window);
				K.cut(intIdx1, W1, intIdx2, W2, crossProduct(vertices[i], vertices[i + 1], K[0]) > 0);
			}
			return K;
		}

		void draw(sf::RenderWindow& window) const
		{
			if (vertices.size() == 0)
				return;

			sf::Color color(0, 250, 150, 255);
			if (!isValid)
				color = sf::Color(255, 25, 25, 255);

			sf::CircleShape circle(4.0, 8);
			circle.setOrigin(sf::Vector2f(4.0, 4.0));
			circle.setFillColor(sf::Color(color.r, color.g, color.b, 100));
			circle.setOutlineColor(color);
			circle.setOutlineThickness(1);

			if (vertices.size() == 1)
			{
				sf::Vertex point(sf::Vector2f(vertices[0].x, vertices[0].y), color);
				window.draw(&point, 1, sf::Points);
				circle.setPosition(point.position);
				window.draw(circle);
				return;
			}

			sf::Vertex line[2];
			line[0].color = line[1].color = color;
			for (size_t i = 0; i < vertices.size() - 1; ++i)
			{
				line[0].position = sf::Vector2f(vertices[i].x, vertices[i].y);
				line[1].position = sf::Vector2f(vertices[i + 1].x, vertices[i + 1].y);
				window.draw(line, 2, sf::Lines);
				circle.setPosition(line[0].position);
				window.draw(circle);
			}
			line[0].position = sf::Vector2f(vertices[0].x, vertices[0].y);
			line[1].position = sf::Vector2f(vertices.back().x, vertices.back().y);
			window.draw(line, 2, sf::Lines);
			circle.setPosition(line[1].position);
			window.draw(circle);
		}

		void drawRays(sf::RenderWindow& window) const
		{
			if (vertices.size() < 3)
				return;

			const sf::Color color(255, 253, 210, 20);

			sf::Vertex trig[3];
			for (size_t i = 1; i < vertices.size() - 1; ++i)
			{
				if (!isReflex(vertices[i - 1], vertices[i], vertices[i + 1]))
				{
					Vertex inf = Equation::toInfinite(vertices[i], vertices[i - 1]);
					trig[0].position = sf::Vector2f(inf.x, inf.y);
					trig[0].color = color;

					trig[1].position = sf::Vector2f(vertices[i].x, vertices[i].y);
					trig[1].color = color;

					inf = Equation::toInfinite(vertices[i], vertices[i + 1]);
					trig[2].position = sf::Vector2f(inf.x, inf.y);
					trig[2].color = color;

					window.draw(trig, 3, sf::Triangles);
				}
			}
			if (!isReflex(vertices.back(), vertices[0], vertices[1]))
			{
				Vertex inf = Equation::toInfinite(vertices[0], vertices.back());
				trig[0].position = sf::Vector2f(inf.x, inf.y);
				trig[0].color = color;

				trig[1].position = sf::Vector2f(vertices[0].x, vertices[0].y);
				trig[1].color = color;

				inf = Equation::toInfinite(vertices[0], vertices[1]);
				trig[2].position = sf::Vector2f(inf.x, inf.y);
				trig[2].color = color;

				window.draw(trig, 3, sf::Triangles);
			}

			if (!isReflex(vertices[vertices.size() - 2], vertices.back(), vertices[0]))
			{
				Vertex inf = Equation::toInfinite(vertices.back(), vertices[vertices.size() - 2]);
				trig[0].position = sf::Vector2f(inf.x, inf.y);
				trig[0].color = color;

				trig[1].position = sf::Vector2f(vertices.back().x, vertices.back().y);
				trig[1].color = color;

				inf = Equation::toInfinite(vertices.back(), vertices[0]);
				trig[2].position = sf::Vector2f(inf.x, inf.y);
				trig[2].color = color;

				window.draw(trig, 3, sf::Triangles);
			}
		}

		inline static float crossProduct(const Vertex& v1, const Vertex& v2, const Vertex& v3)
		{
			return ((v2.x - v1.x) * (v3.y - v2.y) - (v3.x - v2.x) * (v2.y - v1.y));
		}
		inline static bool isReflex(const Vertex& v1, const Vertex& v2, const Vertex& v3)
		{
			return crossProduct(v1, v2, v3) > 0;
		}

		bool load(const std::string& path)
		{
			std::ifstream in(path);

			if (!in)
				return false;

			vertices.clear();
			std::string line;
			try
			{
				while (std::getline(in, line))
				{
					const size_t temp = line.find(',');
					addVertex(Vertex(std::stof(line.substr(1, temp)), std::stof(line.substr(temp + 1, line.size() - 1))));
				}
			}
			catch (...)
			{
				return false;
			}
			return true;
		}

		friend std::ostream& operator<<(std::ostream& os, const Polygon& obj)
		{
			for (size_t i = 0; i < obj.vertices.size(); ++i)
				os << '(' << obj.vertices[i].x << ',' << obj.vertices[i].y << ")\n";
			return os;
		}
	};
}

class DragNDropHelper
{
	bool _isInUse = false;
	sf::Vector2f _initialPos;

public:

	inline void use(const sf::Vector2f& point) { _isInUse = true; _initialPos = point; }
	inline void clear() { _isInUse = false; }
	inline void setOrigin(const sf::Vector2f& point) { _initialPos = point; }

	inline bool isInUse() const { return _isInUse; }
	inline sf::Vector2f getDelta(const sf::Vector2f& point) const { return point - _initialPos; }
};

int main()
{
	sf::RenderWindow window(sf::VideoMode(WIN_WIDTH, WIN_HEIGHT), "Kernel of a polygon");
	window.setFramerateLimit(60);

	size_t selected = NAN;
	geo::Polygon inputPoly;
	geo::Kernel kernel;

	DragNDropHelper _dragger;

	bool modified = true, showLight = false;

	while (window.isOpen())
	{
		sf::Event event;
		while (window.pollEvent(event))
		{
			if (event.type == sf::Event::Closed)
				window.close();
			else if (event.type == sf::Event::MouseMoved)
			{
				if (selected != NAN)
				{
					inputPoly.setPosition(selected, static_cast<sf::Vector2f>(sf::Mouse::getPosition(window)));
					modified = true;
				}
			}
			else if (event.type == sf::Event::MouseButtonReleased)
			{
				if (_dragger.isInUse())
				{
					_dragger.clear();
					selected = NAN;
				}
				else
				{
					const sf::Vector2i mPos = sf::Mouse::getPosition(window);
					inputPoly.addVertex(geo::Vertex(mPos.x, mPos.y));
					modified = true;
				}
			}
			else if (event.type == sf::Event::MouseButtonPressed)
			{
				const sf::Vector2f mPos = static_cast<sf::Vector2f>(sf::Mouse::getPosition(window));
				selected = inputPoly.find(mPos);
				if(selected != NAN)
					_dragger.use(mPos);
			}
			else if (event.type == sf::Event::KeyPressed)
			{
				if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::K))
				{
					kernel = inputPoly.getKernel(window);
				}
				else if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::O))
				{
					std::cout << "-v-v-v-v-v-\n" << inputPoly << "-^-^-^-^-^-\n";
				}
				else if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::I))
				{
					std::string temp = openFileDialog(window.getSystemHandle());
					if (temp.size() && !inputPoly.load(temp))
						std::cout << "Error reading file\n";
				}
				else if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::L))
				{
					showLight = !showLight;
				}
				else if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::C))
				{
					inputPoly.clear();
					modified = true;
				}
				else if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::BackSpace))
				{
					const size_t temp = inputPoly.find(static_cast<sf::Vector2f>(sf::Mouse::getPosition(window)));
					if (temp != NAN)
					{
						inputPoly.popVertex(temp);
						modified = true;
					}
				}
			}
		}

		if (modified)
		{
			sf::Clock c;
			kernel = inputPoly.getKernel();
			sf::Time t = c.getElapsedTime();
			std::cout << "Input size: " << inputPoly.size() << " Kernel size: " << kernel.size() << " Time: " << t.asMilliseconds() << "ms\n";

			modified = false;
		}

		window.clear();
		if(showLight)
			inputPoly.drawRays(window);
		inputPoly.draw(window);
		kernel.draw(window);;
		window.display();
	}

	return 0;
}

